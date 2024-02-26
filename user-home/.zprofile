# shellcheck disable=SC2148
if [ -z "$SSH_AUTH_SOCK" ]; then
    # Check for a currently running instance of the agent
    RUNNING_AGENT="$(pgrep -c 'ssh-agent -s' | tr -d '[:space:]')"
    if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> ".ssh/ssh-agent"
    fi
    eval "$(cat .ssh/ssh-agent)"
fi

for possiblekey in ${HOME}/.ssh/id_*; do
    if grep -q PRIVATE "$possiblekey"; then
        ssh-add "$possiblekey"
    fi
done
