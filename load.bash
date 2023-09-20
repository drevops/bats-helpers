##
# Helpers and assertions for BATs testing.
#
# Central loading point for all the helpers and assertions.
# @see https://bats-core.readthedocs.io/en/stable/writing-tests.html#bats-load-library-load-system-wide-libraries
#
# shellcheck disable=1090

source "$(dirname "${BASH_SOURCE[0]}")/src/assert.base.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/assert.string.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/assert.file.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/assert.git.bash"

source "$(dirname "${BASH_SOURCE[0]}")/src/mock.bash"
source "$(dirname "${BASH_SOURCE[0]}")/src/steps.bash"
