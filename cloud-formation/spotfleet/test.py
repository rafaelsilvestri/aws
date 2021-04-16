#!/usr/bin/env python3

import base64
import io

clientToken = "123"
userData = f'''#!/bin/bash
echo 'execution id {clientToken}' > /tmp/execution.txt'''
encoded = base64.b64encode(str.encode(userData)).decode("ascii")


print("-------------")
print(userData)
print(encoded)
