#!/usr/bin/env bash
##
# @file
# Central loading point for all helpers and assertions.
#
# @see https://bats-core.readthedocs.io/en/stable/writing-tests.html#bats-load-library-load-system-wide-libraries
#
# shellcheck disable=SC1090

source "$(dirname "${BASH_SOURCE[0]}")/src/assert.base.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/assert.string.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/assert.command.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/assert.line.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/assert.file.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/assert.git.bash"

source "$(dirname "${BASH_SOURCE[0]}")/src/cleanup.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/retry.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/file.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/fixture.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/dataprovider.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/mock.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/steps.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/tui.bash"
