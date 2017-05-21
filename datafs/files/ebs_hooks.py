"""This module allows backup and restore to have hooks that can occure before
during or after a backup and restore take place"""

import os
import subprocess


def execute_shell_command(command):
    """Takes a string to execute in a shell subprocess and checks the exit status
    of that command"""
    try:
        cmnd_output = subprocess.check_output(command,
                                              stderr=subprocess.STDOUT,
                                              shell=True)
    except subprocess.CalledProcessError as exc:
        raise Exception(
            "Status : FAIL '{0}': \n{1}\n".format(command, exc.output))
    else:
        print "Output from '{0}': \n{1}\n".format(command, cmnd_output)


def execute_hook(hooks, hook_type):
    """Executes a hook, which is a stand alone file. We check to see the file
    exists before we pass it to execute_shell_command"""
    if hook_type in hooks.keys():
        for hook in hooks[hook_type]:
            if os.path.isfile(hook):
                execute_shell_command(hook)
            else:
                raise Exception(
                    "{1} is not a valid file and the hook can not be executed")
