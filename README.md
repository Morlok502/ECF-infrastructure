# ECF-infrastructure  

📅 [**Planning Notion**](https://mirror-paw-f24.notion.site/f2fa7cecae5a4cd4a1792bf963ec744a?v=b71bd3754f5541c1a7c1a23cbb2f1ca9) 📅  
___  
## Table of content
- [ECF-infrastructure](#ecf-infrastructure)
  - [Table of content](#table-of-content)
  - [Activité Type 1 : Automatisation du déploiement d’infrastructure dans le Cloud](#activité-type-1--automatisation-du-déploiement-dinfrastructure-dans-le-cloud)
    - [1. Préparez un kube kubernetes en utilisant Terraform](#1-préparez-un-kube-kubernetes-en-utilisant-terraform)
      - [1.1 Création de l'IAC](#11-création-de-liac)
      - [1.2 Process création de l'infrastructure](#12-process-création-de-linfrastructure)
      - [1.3 Interactions avec kubectl](#13-interactions-avec-kubectl)
      - [1.4 Ressources créées dans AWS](#14-ressources-créées-dans-aws)
    - [2. Ajoutez/configurez les variables d’environnement qui se connectent à la BDD](#2-ajoutezconfigurez-les-variables-denvironnement-qui-se-connectent-à-la-bdd)
  - [Sources utilisées](#sources-utilisées)

## Activité Type 1 : Automatisation du déploiement d’infrastructure dans le Cloud  

### 1. Préparez un kube kubernetes en utilisant Terraform  

#### 1.1 Création de l'IAC

 ✔ Prérequis : installation de Terraform en local [Install Terraform](https://developer.hashicorp.com/terraform/downloads)  
Construction d'un projet terraform, avec les ressources suivantes : 
- 1 VPC
- 2 subnets
- 1 internet gateway
- 1 route table
- 2 route table association
- 1 role iam pour le Cluster eks
- 2 policies associées (AmazonEKSClusterPolicy et AmazonEKSVPCResourceController)
- 1 groupe de sécurité pour le cluster eks
- 1 règle pour le groupe de sécurité
- 1 Cluster
- 1 role pour le node
- 3 policies associées à ce rôle (AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy et AmazonEC2ContainerRegistryReadOnly)
- 1 node groupe

Cette structure suffira pour faire tourner notre container.

Remarque : Le projet a été construit à partir du template fourni par hashicorp : [Github - eks-getting-started](https://github.com/hashicorp/terraform-provider-aws/tree/main/examples/eks-getting-started)  

#### 1.2 Process création de l'infrastructure

✔ Prérequis : avoir installé terraform sur sa machine locale : [Install Terraform](https://developer.hashicorp.com/terraform/downloads)  
Les commandes ci dessous sont utilisées (dans l'ordre) pour créer l'infrastructure sur aws :  
```
terraform init # Initialise le dossier de travail avec les fichiers de configuration de terraform
terraform plan #  Création d'un plan d'exécution / Prévisualisation avant terraform apply
terraform apply # Création de l'infrastructure / Exécution des actions listées dans terraform plan
terraform destroy # Déstruction de toutes les ressources créées
```

#### 1.3 Interactions avec kubectl

✔ Prérequis : pour pouvoir communiquer avec notre Kube, il faut parametrer notre kubeconfig avec une des méthodes ci-dessous : 
- Copier la sortie générée par `terraform apply` (sur le modèle donné par [outputs.tf](outputs.tf)) et la coller dans la configuration de kubectl (**~/.kube/config** sous Linux ou **%USERPROFILE%\.kube\config** sous Windows)  
- Exécuter la commande suivante, en remplaçant `region-code` et `my-cluster` par les valeurs données par la sortie de `terraform apply` : `aws eks update-kubeconfig --region region-code --name my-cluster`  

Une fois la config renseignée, on peut utiliser les commandes suivantes :  

```
kubectl get svc # Lister tous les services
kubectl get all # Lister toutes les ressources
kubectl get nodes # Lister tous les nodes (un seul créé)
kubectl get pods # Lister tous les pods créés (aucun à la création de l'infra)
```
![](img/image.png)  

#### 1.4 Ressources créées dans AWS

- IAM Roles : **studi-eks-ecf-cluster** avec 2 policies affectées  
  ![studi-eks-ecf-cluster](img/image-1.png)  
- IAM Roles : **studi-eks-ecf-node** avec 3 policies affectées  
  ![studi-eks-ecf-node](img/image-2.png)  

- Security Groups 
  ![](img/image-9.png)  

- aws_security_group_rule  

- Le Cluster **studi-ecf-eks-cluster**, le node group **ecf** et le node créé à partir d'une instance t3.small
![cluster, node groupe et node](img/image-8.png)

- VPC : **studi-eks-ecf-node**
 ![studi-eks-ecf-node](img/image-3.png)  

- 2 subnets : **studi-eks-ecf-node**  
![studi-eks-ecf-node](img/image-4.png)  

 - Internet gateways
  ![Alt text](img/image-7.png)  

- Route tables 
  ![Alt text](img/image-5.png)  

 - Route table association  
  ![Alt text](img/image-6.png)  



### 2. Ajoutez/configurez les variables d’environnement qui se connectent à la BDD

❗ Cette partie a été traitée dans le repository [ECF-Hello-world-nestJS](https://github.com/Morlok502/ECF-deploiement-nestJS-Kube).  
➡ Voir [README.md](https://github.com/Morlok502/ECF-deploiement-nestJS-Kube#ecf-hello-world-nestjs) pour le détail de cette étape.  

## Sources utilisées

[Terraform - Provision an EKS Cluster (AWS)](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks)  
[Terraform - Resource: aws_eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)  
[Terraform - Resource: aws_eks_node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group)  
[Terraform - Resource: aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) 
[Terraform - kubernetes_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) 
[Github - terraform-provider-aws](https://github.com/hashicorp/terraform-provider-aws)  
[AWS - Creating an Amazon EKS cluster](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)  
[AWS - Creating a VPC for your Amazon EKS cluster](https://docs.aws.amazon.com/eks/latest/userguide/creating-a-vpc.html)  
[AWS - Création ou mise à jour d'un fichier kubeconfig pour un cluster Amazon EKS](https://docs.aws.amazon.com/fr_fr/eks/latest/userguide/create-kubeconfig.html)  
[Youtube - How to provision AWS EKS using Terraform](https://www.youtube.com/watch?v=KsvfV5iuWqM)  
[Youtube - EKS cluster using management console - Part 1](https://www.youtube.com/watch?v=kDTr3IJfawY)  
[Youtube - EKS cluster using management console - Part 2](https://www.youtube.com/watch?v=IHdWJhMGdXA)  
[Youtube - EKS cluster using management console - Part 3](https://www.youtube.com/watch?v=0amRQQnwwAk)  