#!/usr/bin/env python3.6
import re
def checkcc(n):
    p=[]
    q=0
    p=n.split('-')
    r=''.join(p)
    if (len(r)==16):
        count=0
        if re.match('^[4-6]{1}[0-9]{3}[-]?[0-9]{4}[-]?[0-9]{4}[-]?[0-9]{4}[-]?',n):
            for i in range(0,len(r)-1):
                if(r[i]==r[i+1]):
                    count+=1
                    if(count==3):
                        q=1
                        break
                    else:
                        continue
                else:
                    count=0
        else:
            q=1
    else:
        q=1
    if(q==1):
        print("Invalid")
    else:
        print("Valid")
s=int(input())
for i in range(0,s):
    n=input()
    checkcc(n)
    
