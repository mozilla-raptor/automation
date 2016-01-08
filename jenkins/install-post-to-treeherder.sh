#!/bin/bash -x

python --version

# need python 2.7.9 or higher to submit to treeherder b/c of this:
# https://urllib3.readthedocs.org/en/latest/security.html#insecureplatformwarning

# install python 2.7.9 but don't interfere with already installed version
mkdir ${WORKSPACE}/Python279
cd ${WORKSPACE}/Python279
wget http://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz
tar -zxvf Python-2.7.9.tgz
cd Python-2.7.9/
mkdir localpy
./configure --prefix=${WORKSPACE}/Python279/Python-2.7.9/localpy
make
make install

# start a virtualenv with this version of python
cd ${WORKSPACE}
virtualenv raptor-env -p ${WORKSPACE}/Python279/Python-2.7.9/localpy/bin/python2.7
source raptor-env/bin/activate

python --version

git clone https://github.com/mozilla-raptor/post-to-treeherder.git
cd post-to-treeherder
pip install -r requirements.txt
cd ..

# grab the gecko revision from device using fxos-device-service
# and write to file; the treeherder submisison code needs it

${WORKSPACE}/automation/jenkins/get-gecko.js ${ANDROID_SERIAL} 2>&1 | tee ${WORKSPACE}/gecko-rev.txt

exit 0
