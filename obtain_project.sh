#!/bin/bash

/usr/bin/expect << EOF
set timeout 100
spawn git clone -b $2 $1
expect {
        Username {send "$3\n";exp_continue}
        Password {send "$4\n"}
}
expect {

        timeout {exit 10}
        eof
}
EOF

if [ $? = 10 ]; then
	echo "拉取代码超时"
fi
