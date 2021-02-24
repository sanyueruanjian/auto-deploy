#!/bin/bash

/usr/bin/expect << EOF
set timeout 100
spawn git clone -b $3 $2
expect {
        Username {send "$4\n";exp_continue}
        Password {send "$5\n"}
}
expect {

        timeout {exit 10}
        eof
}
EOF

if [ $? = 10 ]; then
	echo "拉取代码超时"
fi
