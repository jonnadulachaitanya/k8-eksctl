!/bin/bash
#DevOps Bootstrap Script
#Installs Docker, EKS tools and Resizes EBS

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

ARCH=amd64
PLATFORM=$(uname -s)_$ARCH


#Function to Validate Command Status

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2 ... $R FAILURE $N"
        echo "Check logs at $LOGFILE"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}


#Root User Check

if [ $USERID -ne 0 ]
then
    echo -e "$R Please run this script with root access. $N"
    exit 1
else
    echo -e "$G You are running as root user. $N"
fi


#Docker Installation

echo -e "$Y Installing Docker... $N"

yum install -y yum-utils &>> $LOGFILE
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &>> $LOGFILE
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y &>> $LOGFILE
VALIDATE $? "Docker package installation"

systemctl start docker &>> $LOGFILE
systemctl enable docker &>> $LOGFILE
VALIDATE $? "Docker service setup"

usermod -aG docker ec2-user &>> $LOGFILE


#EBS Resize Section

echo -e "$Y Resizing EBS Volume... $N"

#Install growpart utility
yum install -y cloud-utils-growpart &>> $LOGFILE
VALIDATE $? "Installing growpart"

echo "Current block devices:"
lsblk

#Resize Partition (Modify if your partition number differs)
growpart /dev/nvme0n1 4 &>> $LOGFILE
VALIDATE $? "Resizing partition"

#Extend Logical Volumes
lvextend -l +50%FREE /dev/RootVG/rootVol &>> $LOGFILE
VALIDATE $? "Extending root logical volume"

lvextend -l +50%FREE /dev/RootVG/varVol &>> $LOGFILE
VALIDATE $? "Extending var logical volume"

#Resize Filesystems (XFS)
xfs_growfs / &>> $LOGFILE
VALIDATE $? "Resizing root filesystem"

xfs_growfs /var &>> $LOGFILE
VALIDATE $? "Resizing var filesystem"


#eksctl Installation

echo -e "$Y Installing eksctl... $N"

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz" &>> $LOGFILE
tar -xzf eksctl_${PLATFORM}.tar.gz -C /tmp &>> $LOGFILE
rm -f eksctl_${PLATFORM}.tar.gz
mv /tmp/eksctl /usr/local/bin &>> $LOGFILE

eksctl version &>> $LOGFILE
VALIDATE $? "eksctl installation"


#kubectl Installation

echo -e "$Y Installing kubectl... $N"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &>> $LOGFILE
chmod +x kubectl
mv kubectl /usr/local/bin/ &>> $LOGFILE

kubectl version --client &>> $LOGFILE
VALIDATE $? "kubectl installation"


#kubens Installation

echo -e "$Y Installing kubens... $N"

yum install -y git &>> $LOGFILE
git clone https://github.com/ahmetb/kubectx /opt/kubectx &>> $LOGFILE
ln -sf /opt/kubectx/kubens /usr/local/bin/kubens &>> $LOGFILE
VALIDATE $? "kubens installation"


#Completion Message

echo -e "$G All installations completed successfully! $N"
echo -e "Log file: $LOGFILE"
