# Manual setup procedure

1. Test on RHEL with Ubuntu container
1. Test on RHEL
1. Test on RHEL with a UBI container
1. Test on OpenShift

## Whisper
```
# create virtual env
python -m venv venv
. venv/bin/activate

# pip install whisper
pip install -U openai-whisper

# install the RHEL 9 EPEL Repository
dnf -y install https://download.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# install the rpmfusion repos
dnf -y install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm

# install the rpmfusion repos 
dnf -y install --nogpgcheck https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm

# In order to install libSDL, you’ll need to enable codeready-builder for RHEL 9
subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms

# install ffmpeg
dnf -y install ffmpeg

# download audio file - we used "Address at Rice University in Houston, Texas on the Nation's Space Effort, 12 September 1962"
https://www.jfklibrary.org/asset-viewer/archives/jfkwha

# install rust tools
pip install setuptools-rust

# run whisper turbo model - don't start with turbo
# Available models https://github.com/openai/whisper?tab=readme-ov-file#available-models-and-languages 
whisper kennedy_rice_1962_speech.mp4 --model tiny.en
```

## Reference

- [Whisper GitHub](https://github.com/openai/whisper?tab=readme-ov-file#available-models-and-languages)
- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
- [ffmpeg install](https://www.benholcomb.com/ffmpeg-on-rhel8/)
