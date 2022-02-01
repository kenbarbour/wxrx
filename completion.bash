#!/usr/bin/env bash
# This is the tab-completion script for wxrx
# To use it, either:
#  * source this file
#  * symlink this file to `/etc/bash_completion.d/wxrx_completion.bash`
complete -W 'help predict record decode pase update schedule' wxrx
