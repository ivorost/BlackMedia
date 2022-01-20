
AUTHOR="$1"
REPO="$2"

if [ -d "repository/$REPO" ]
then
    cd "repository/$REPO"
    git reset --hard HEAD^
    git pull --ff-only
else
    git clone https://github.com/$AUTHOR/$REPO repository/$REPO
fi


