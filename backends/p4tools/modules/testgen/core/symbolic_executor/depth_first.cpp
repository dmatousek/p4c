#include "backends/p4tools/modules/testgen/core/symbolic_executor/depth_first.h"

#include <optional>
#include <vector>

#include "backends/p4tools/common/core/solver.h"
#include "backends/p4tools/common/lib/formulae.h"
#include "backends/p4tools/common/lib/util.h"
#include "gsl/gsl-lite.hpp"
#include "ir/ir.h"
#include "lib/error.h"
#include "lib/timer.h"

#include "backends/p4tools/modules/testgen/core/program_info.h"
#include "backends/p4tools/modules/testgen/core/small_step/small_step.h"
#include "backends/p4tools/modules/testgen/core/symbolic_executor/symbolic_executor.h"
#include "backends/p4tools/modules/testgen/lib/exceptions.h"
#include "backends/p4tools/modules/testgen/lib/execution_state.h"
#include "backends/p4tools/modules/testgen/options.h"

namespace P4Tools::P4Testgen {

DepthFirstSearch::DepthFirstSearch(AbstractSolver &solver, const ProgramInfo &programInfo)
    : SymbolicExecutor(solver, programInfo) {}

bool DepthFirstSearch::pickSuccessor(StepResult successors) {
    if (successors->empty()) {
        return false;
    }

    // If there is only one successor, choose it and move on.
    if (successors->size() == 1) {
        executionState = successors->at(0).nextState;
        return true;
    }

    // If there are multiple successors, try to pick one.
    // Pick a successor branch at random to preserve some non-determinism.
    executionState = popRandomBranch(*successors).nextState;
    // Add the remaining tests to the unexplored branches.
    unexploredBranches.insert(unexploredBranches.end(), successors->begin(), successors->end());
    return true;
}

void DepthFirstSearch::run(const Callback &callback) {
    while (true) {
        try {
            if (executionState->isTerminal()) {
                // We've reached the end of the program. Call back and (if desired) end execution.
                bool terminate = handleTerminalState(callback, *executionState);
                if (terminate) {
                    return;
                }
            } else {
                // Take a step in the program, choose a branch, and continue execution. If
                // branch selection fails, fall through to the roll-back code below. To help reduce
                // calls into the solver, only guarantee viability of the selected branch if more
                // than one branch was produced.
                // State successors are accompanied by branch constraint which should be evaluated
                // in the state before the step was taken - we copy the current symbolic state.
                StepResult successors = step(*executionState);
                auto success = pickSuccessor(successors);
                if (success) {
                    continue;
                }
            }
        } catch (TestgenUnimplemented &e) {
            // If strict is enabled, bubble the exception up.
            if (TestgenOptions::get().strict) {
                throw;
            }
            // Otherwise we try to roll back as we typically do.
            ::warning("Path encountered unimplemented feature. Message: %1%\n", e.what());
        }

        // Roll back to a previous branch and continue execution from there, but if there are no
        // more branches to explore, finish execution. Not all branches are viable, so we loop
        // until either we run out of unexplored branches or we find a viable branch.
        if (unexploredBranches.empty()) {
            return;
        }
        // Select a new branch by iterating over all branches
        Util::ScopedTimer chooseBranchtimer("branch_selection");
        // Pick the top branch from the stack
        executionState = unexploredBranches.back().nextState;
        unexploredBranches.pop_back();
    }
}

}  // namespace P4Tools::P4Testgen
