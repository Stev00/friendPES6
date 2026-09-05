@echo off
@start twistd -ny ./etc/server6.tac -l ./log/sixserver.log

rem If the command above fails to start the twistd.exe process
rem then try the following one, instead: it allows to see the
rem error message printed out
rem
rem twistd -ny ./etc/server6.tac -l ./log/sixserver.log
