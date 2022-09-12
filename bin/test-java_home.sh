#!/usr/bin/env bash

j18home=$(/usr/libexec/java_home -v 1.8)

if [ "${j18home}" != "/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home" ]
then
    echo "java_home execution failed with result: ${j18home}"
fi
