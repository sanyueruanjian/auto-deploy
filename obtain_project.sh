#!/usr/bin/expect
set gitAddress [lindex $argv 0]
set gitUsername [lindex $argv 1]
set gitPassword [lindex $argv 2]

spawn git clone $gitAddress
expect "Username"
send "$gitUsername\n"
expect "Password"
send "$gitPassword\n"
expect eof
