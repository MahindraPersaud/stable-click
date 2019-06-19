from pathlib import Path
import subprocess

import click
import python_terraform as pt

#from stable_click import utils

DEPLOYMENT_DIRECTORY = Path.cwd()
BASE_DIRECTORY = Path(__file__).parent
TERRAFORM_DIRECTORY = str(BASE_DIRECTORY / "terraform")


@click.group()
def main():
    pass

def deployment_options(deployment_function):
    deployment_function = click.option(
        "--py",
        default="3.7",
        help='Python version. Options are 3.7, 3.6, 3.5, 2.7.',
    )(deployment_function)
    deployment_function = click.option(
        "--instance_type",
        default="t2.micro",
        help="See what's available here https://aws.amazon.com/ec2/instance-types/",
    )(deployment_function)
    deployment_function = click.option(
        "--private_key_path", default="~/.ssh/id_rsa"
    )(deployment_function)
    deployment_function = click.option(
        "--public_key_path", default="~/.ssh/id_rsa.pub"
    )(deployment_function)
    deployment_function = main.command()(deployment_function)

    return deployment_function

@deployment_options
def deploy_cluster(
    #git_path = None,
    public_key_path = None,
    private_key_path = None,
    py = None,
    instance_type = None,
):
    tf = pt.Terraform()
    tf.init(
        dir_or_plan = str(DEPLOYMENT_DIRECTORY),
        from_module = TERRAFORM_DIRECTORY,
        capture_output = False,
    )
    
    return_code, _, _ = tf.apply(capture_output = False, skip_plan=True)

    subprocess.call(str(BASE_DIRECTORY/"k8Communication.sh"))
    
    #subprocess.Popen(['terraform', 'output', 'kubeconfig', '>', '~/.kube/config'])
    #subprocess.call(['terraform', 'output', 'config_map_aws_auth > config-map-aws-auth.yaml'])
    
    #tf.output('kubeconfig > ~/.kube/config')
    #tf.output('config_map_aws_auth > config-map-aws-auth.yaml')

    #Popen("terraform output kubeconfig > ~/.kube/config", shell = True)
    #Popen("terraform output config_map_aws_auth > config-map-aws-auth.yaml",shell = True)
    #Popen("kubectl apply -f config-map-aws-auth.yaml", shell = True)
    #Popen("eksctl create node-group --cluster=terraform-eks-halfclick-cluster -n=worker_nodes -t=t2.micro -m=1 -M=)

@deployment_options
def deploy_app(
    git_path,
    public_key_path = None,
    private_key_path = None,
    py = None,
    instance_type = None,
):
    #Create a pod
    
    # Put docker image into Pod

    # Deploy App
    '''
    cluster_name = "terraform-eks-halfclick-cluster"
    node_group_name = "worker-nodes"
    instance_type = "t2.micro"
    nodes_min = "1"
    nodes_max = "3"
    call(["eksctl create node-group", "--cluster=" + str(cluster_name), "-n" + node_group_name, "-t" + instance_type, "-m" + nodes_min, "-M" + nodes_max], "--asg-acess")
    '''

@main.command()
def destroy_cluster():
    # Ensure that the correct terraform state files exist in the deployment
    #utils.pre_destroy_check(DEPLOYMENT_DIRECTORY)
    tf = pt.Terraform()
    tf.destroy(capture_output = False)