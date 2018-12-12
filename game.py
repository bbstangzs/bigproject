#!/usr/local/bin/python3
import pickle,random,getpass,os,time,sys
from datetime import datetime

def new_game ():
    while True:
        username=input('请输入新建用户名:')
        data=os.path.join("/tmp/save",username+".txt")
        if not os.path.isfile(data):
            break
        print("用户已存在!请重试")
    while True:
        passwd=getpass.getpass('请设置密码:')
        passwd2=getpass.getpass('请确认密码:')
        if passwd == passwd2:
            break
        print("两次密码不一致")
    player_info={"username":username,"passwd":passwd,"liliang":10,"minjie":10,"tizhi":10,"zhili":10}
    with open(data,"wb") as file:
        pickle.dump(player_info,file)
    return player_info

def save_game (username,play_info):
    data=os.path.join("/tmp/save",username+".txt")
    with open(data,"wb") as file:
        pickle.dump(play_info,file)

def load_game ():
    while True:
        username=input("请输入用户名:")
        passwd=getpass.getpass('请输入密码:')
        userinfo=os.path.join("/tmp/save",username+".txt")
        if not os.path.isfile(userinfo):
            print("用户名不存在或密码错误!")
        else:
            with open(userinfo,"rb") as file:
                player_info=pickle.load(file)
                if passwd == player_info["passwd"]:
                    break
                print("用户名不存在或密码错误!")
    return player_info

def exit_game ():
    mksure="""
请确认是否已存档
1)已存档,退出
2)暂不退出
(输入1或2)默认:2
"""
    exit_choice=input(mksure)
    if exit_choice == "1":
        print("再见,我会想念你的!")
        exit()

def main_menu ():
    if not os.path.isdir("/tmp/save"):
        os.mkdir("/tmp/save")
    print("欢迎来到荒野求生!")
    time.sleep(1)
    tips="""-----------
1)开始新游戏
2)读取旧存档
3)退出游戏
请选择(1/2/3)
:"""
    choice=input(tips)
    ch_list={"1":new_game,"2":load_game,"3":exit_game}
    while True:
        if choice not in ["1","2","3"]:
            choice=input("输入错误,请重新输入(1/2/3):")
        break
    return ch_list[choice]()

def main_game (player_info):
    print("进入游戏")
    x=0
    while x < 3:
        y=0
        while y < 4:
            print("\r载入世界中"+"." * y+" " * (4-y),end="")
            sys.stdout.flush()
            time.sleep(0.5)
            y+=1
        x+=1
    print("\n")
    print(player_info)


if __name__ == "__main__":
    player_info=main_menu()
    main_game(player_info)
