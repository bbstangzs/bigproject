import requests
import json

def ding_talk (url,content,atperson):
    headers = {'Content-Type': 'application/json;charset=utf-8'}
    message={
         "msgtype": "text",
         "text": {
             "content": content
         },
         "at": {
             "atMobiles": [
                 atperson
             ],
             "isAtAll": False
         }
     }
    r = requests.post(url,data=json.dumps(message),headers=headers)
    return r.json()

if __name__ == '__main__':
    url="机器人webhook地址"
    content="发送内容"
    atperson="被@的人"
    ding_talk(url,content,atperson)
