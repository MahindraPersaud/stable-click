Stable-click deployment for Flask Applications

## Before you Can Deploy

Deployment might be quick and easy, however, installing dependecies, making your AWS account, and ensuring your project is compatible with stable-click is not. If you've already setup yur machine and your project skip to the [quick-start guide](#quick-start-guide).

Windows is not directly supported at this time. The [Ubuntu subsystem](https://helloacm.com/the-ubuntu-sub-system-new-bash-shell-in-windows-10/) for Windows 10 is recommended. 

### AWS Setup

1. Create a [AWS account](https://aws.amazon.com/) (or use an existing one).
2. Create an [IAM admin user and group](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html). AWS credentialling is confusing. This instruction creates a new sub-user that will be safer to use than the root account you just created in step 1.
3. Get the access key and secret access key from the IAM administrator user you just created. 
  - Go to the [IAM console](https://console.aws.amazon.com/iam/home?#home)
  - Choose **Users** and then the administrator user you just created.
  - Select the **Security Credentials** tab and then hit **Create Access Key**
  - Choose **Show**
  - We need to export these as enviornment variables in your `~/.bash_profile`. You should add something that looks like this to the bottom of your profile using your favorite text editor, where the keys are your own of course:
  ```bash
  export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
  export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  ```
  Then source your profile `souce ~/.bash_profile` and now your laptop will be fully authorized to create resources on AWS!
  
### Create RSA Key Pair

1. Check to see if you already have keys with default names: `ls ~/.ssh` (It's fine if it says the directory `~/.ssh` doesn't exist move on to step 2). If you have two files with names `id_rsa` and `id_rsa.pub` then you are all set to skip this section, if not then continue on to creating the key pair.
2. `ssh-keygen`
3. Continue by pressing enter repeatedly (you don't need to enter anything in the text boxes) until you see something like this 
```
+--[ RSA 2048]----+
|       o=.       |
|    o  o++E      |
|   + . Ooo.      |
|    + O B..      |
|     = *S.       |
|      o          |
|                 |
|                 |
|                 |
+-----------------+
```

### Software Requirements

- You need terraform version 0.11.x installed.
  - MacOs: `brew install terraform`. If you don't have homebrew, install it with this command: `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`.
. 
  - linux: https://www.terraform.io/downloads.html

- You need docker installed.
  - MacOs: https://docs.docker.com/docker-for-mac/install/
.
  - linux: https://docs.docker.com/install/

- You need Kubectl version 1.12 installed.
  - MacOs/linux: `curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/darwin/amd64/kubectl`

- You need aws-iam-autenticator installed.
  - MacOS: `brew install aws-iam-authenticator`
.
  - linux: 
  1. `curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator`
  2. `chmod +x ./aws-iam-authenticator`
  3. `mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH`
  4. `echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc`
  

### Setting up Kubectl

1. Make the kubectl binary executable
  - `chmod +x ./kubectl`
2. Move the binary to your PATH
  - `sudo mv ./kubectl /usr/local/bin/kubectl`
3. Test to ensure version 1.12 is installed
  - `kubectl version`

### Setting up Docker

1. Create a docker account at https://hub.docker.com/
2. In terminal run the following command: `docker login --username=yourhubusername --email=youremail@company.com` replacing with your docker credentials. Note: Docker will require sudo so please ensure that the current account has root capabilities. For linux: https://docs.docker.com/install/linux/linux-postinstall/

### App Compatibility

Stable-click has several strict requirements for apps it can deploy. Rigid specifications keeps the tool easy to use. Check out some example [stable-click compatible projects](#example-apps) that are compliant.

#### Directory Structure 

- It is strongly recommended that your directory structure be flat. Having your app defined, your templates, and your static folder in a nested subfolder e.g. in `yourapp/flaskexample/` might cause problems. 
- There must be a python file called `main.py` in the root of your project directory that will run your app. _**The name and the location are non-negotiable.**_ The file might looks something like:
```python
from views import app

if __name__ == '__main__':
  app.run(host='0.0.0.0', port=80)
```
- As of now, run your app in `main.py` on `host='0.0.0.0'` and `port=80`

#### Requirements File

Stable-click builds a fresh python environment in ubuntu for every deployment. You need to clearly specify which python requirements your app depends on.

- Put the name (and potentially the version number) of every requirement in a file `requirements.txt` in the root of your project. Once again, _**The name and the location of `requirements.txt` are non-negotiable.**_ 

- If you haven't been keeping track of your requirements you could:
  - Use a tool like [pigar](https://github.com/damnever/pigar) to automatically generate it based on searching your project.
  - If you've been using a conda environment or a virtualenv for the project you can run `pip freeze > requirements.txt`

- **HINT:** A good way to test if your `requirements.txt` file is comprehensive is to create a fresh conda or virtual enviornment and try to run your app after installing from the file.
```bash
conda create -n test_env python=3.6
source activate test_env
pip install -r requirements.txt
python run.py
```

## Quick-start Guide

Consult the [app compatibility guidelines](#app-compatibility) before deploying for the first time. You may have to restructure your project before it will work with stable-click.

### Deploy Instructions

1. Clone the repo
2. Install the stable-click package (from inside the cloned repo) `pip3 install -e .`
3. Make a new directory to track the state of your deployment. It can be anywhere. This new *deployment directory* has nothing to do with your project directory that has your code. It will hold the backend state files for the deployment. Any time you want to reference this specific deployment you must be using stable-click from its deployment directory.
4. Deploy your cluster! Inside the deployment directory you just created, run for cluster deployment
```
stable-click deploy-cluster
```
5. Deploy your project! Inside the deployment directory you just created, run for github deployment (**NOTE:** if you didn't use the default names when you generated your RSA keys, or if you're on windows, then you will have to specify the paths with the `--private_key_path` and `--public_key_path`command line options)
```
stable-click deploy-app https://github.com/gusostow/EXAMPLE-localtype_site
```

Your app should now be publicly available from the `public_dns` output in your console. If you want to ssh into the instance this can be done with `ssh ubuntu@<public-dns>`

### Destroy Instructions

1. Navigate to your deployment directory, which is where the terraform state is located.
2. Run `stable-click destroy-cluster`

### Updating your App

As of now stable-click does not provision automatic CI/CD support to keep your deployment up to date with pushes to your app's repo. To make updates:
1. Push your changes to github
2. Make sure you are inside the directory used for deployment, then destroy and re-deploy your project:
```
stable-click delete-app <github-link-to-your-app>
stable-click deploy-app <github-link-to-your-app>
```

## Troubleshooting your Deployment

A lot can go wrong with a one size fits all automatic deployment. Most issues will be visible with some detective work.

### Problems with Provisioning the Server and Building your App Environment

Build logs for installations on the server and building the docker environment are piped to console. Here you can see if there's an issue with making the ssh connection to remotely execute commands, cloning your repo to the server, or installing your requirements. If your url is completely unaccessable, then the error can likely be diagnosed here.

### Problems with Running your Code

However, once the environment is set up, the server logs won't be directly visible in your console. If you get a 403 error when you visit your webpage url, then that means there is an error in your code, which probably has something to do with porting it a docker environment.

You need to ssh into the server to view get visibility in those logs:
1. Get shell access to the server. `ssh ubuntu@<outputed-dns-address>`. You don't need to specify the path to a key file because you already did that in the deploy phase.
2. `cd app`
3. View the logs. `docker-compose logs`

Here you will find the python errors you are accustomed to diagnosing when developing your app.

### Other Fixes to Common Problems

#### Broken Paths
- **Problem:** Absolute paths to files like datasets or models will break. The path `~/gusostow/python/myproject/data/data.csv` might work fine on your laptop, it won't in the docker container built for your app, which has a different directory structure.
- **Solution:** Switch to referencing paths relatively to the python file that uses them, so they will be invariant to where the script is run. The `__file__` variable has that information.

## Example Apps 

- [Hosteldirt](https://github.com/gusostow/EXAMPLE-hosteldirt)

