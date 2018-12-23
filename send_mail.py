from email.mime.text import MIMEText
from smtplib import SMTP
import getpass


def send_mail (text,subject,sender,receivers,user,passwd,smtpserver,port=25):
    message = MIMEText(text, 'plain', 'utf8')
    message['Subject'] = subject
    smtp=SMTP()
    smtp.connect(smtpserver,port)
    smtp.login(user,passwd)
    smtp.sendmail(sender,receivers,message.as_bytes())

if __name__ == '__main__':
    smtpserver="smtp.163.com"  #邮件服务器
    subject='标题'
    text="内容"
    sender= '发件人邮箱'
    receivers='收件人邮箱'
    # passwd=getpass.getpass()
    passwd="服务器授权码"
    send_mail(text,subject,sender,receivers,sender,passwd,smtpserver)