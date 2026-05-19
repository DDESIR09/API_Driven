------------------------------------------------------------------------------------------------------
ATELIER API-DRIVEN INFRASTRUCTURE
------------------------------------------------------------------------------------------------------
L’idée en 30 secondes : **Orchestration de services AWS via API Gateway et Lambda dans un environnement émulé**.  
Cet atelier propose de concevoir une architecture **API-driven** dans laquelle une requête HTTP déclenche, via **API Gateway** et une **fonction Lambda**, des actions d’infrastructure sur des **instances EC2**, le tout dans un **environnement AWS simulé avec LocalStack** et exécuté dans **GitHub Codespaces**. L’objectif est de comprendre comment des services cloud serverless peuvent piloter dynamiquement des ressources d’infrastructure, indépendamment de toute console graphique.Cet atelier propose de concevoir une architecture API-driven dans laquelle une requête HTTP déclenche, via API Gateway et une fonction Lambda, des actions d’infrastructure sur des instances EC2, le tout dans un environnement AWS simulé avec LocalStack et exécuté dans GitHub Codespaces. L’objectif est de comprendre comment des services cloud serverless peuvent piloter dynamiquement des ressources d’infrastructure, indépendamment de toute console graphique.
  
-------------------------------------------------------------------------------------------------------
Séquence 1 : Codespace de Github
-------------------------------------------------------------------------------------------------------
Objectif : Création d'un Codespace Github  
Difficulté : Très facile (~5 minutes)
-------------------------------------------------------------------------------------------------------
RDV sur Codespace de Github : <a href="https://github.com/features/codespaces" target="_blank">Codespace</a> **(click droit ouvrir dans un nouvel onglet)** puis créer un nouveau Codespace qui sera connecté à votre Repository API-Driven.
  
---------------------------------------------------
Séquence 2 : Création de l'environnement AWS (LocalStack)
---------------------------------------------------
Objectif : Créer l'environnement AWS simulé avec LocalStack  
Difficulté : Simple (~5 minutes)
---------------------------------------------------

Dans le terminal du Codespace copier/coller les codes ci-dessous etape par étape :  

**Installation de l'émulateur LocalStack**  
```
sudo -i mkdir rep_localstack
```
```
sudo -i python3 -m venv ./rep_localstack
```
```
sudo -i pip install --upgrade pip && python3 -m pip install localstack && export S3_SKIP_SIGNATURE_VALIDATION=0
```
Rendez-vous chez Localstack pour vous créez un Token : https://app.localstack.cloud/
```
localstack auth set-token <YOUR_AUTH_TOKEN>
localstack start -d
```
**vérification des services disponibles**  
```
localstack status services
```
**Réccupération de l'API AWS Localstack** 
Votre environnement AWS (LocalStack) est prêt. Pour obtenir votre AWS_ENDPOINT cliquez sur l'onglet **[PORTS]** dans votre Codespace et rendez public votre port **4566** (Visibilité du port).
Réccupérer l'URL de ce port dans votre navigateur qui sera votre ENDPOINT AWS (c'est à dire votre environnement AWS).
Conservez bien cette URL car vous en aurez besoin par la suite.  

Pour information : IL n'y a rien dans votre navigateur et c'est normal car il s'agit d'une API AWS (Pas un développement Web type UX).

---------------------------------------------------
Séquence 3 : Exercice
---------------------------------------------------
Objectif : Piloter une instance EC2 via API Gateway
Difficulté : Moyen/Difficile (~2h)
---------------------------------------------------  
Votre mission (si vous l'acceptez) : Concevoir une architecture **API-driven** dans laquelle une requête HTTP déclenche, via **API Gateway** et une **fonction Lambda**, lancera ou stopera une **instance EC2** déposée dans **environnement AWS simulé avec LocalStack** et qui sera exécuté dans **GitHub Codespaces**. [Option] Remplacez l'instance EC2 par l'arrêt ou le lancement d'un Docker.  

**Architecture cible :** Ci-dessous, l'architecture cible souhaitée.   
  
![Screenshot Actions](API_Driven.png)   
  
---------------------------------------------------  
## Processus de travail (résumé)

1. Installation de l'environnement Localstack (Séquence 2)
2. Création de l'instance EC2
3. Création des API (+ fonction Lambda)
4. Ouverture des ports et vérification du fonctionnement

---------------------------------------------------
Séquence 4 : Documentation  
Difficulté : Facile (~30 minutes)
---------------------------------------------------
**Complétez et documentez ce fichier README.md** pour nous expliquer comment utiliser votre solution.  
Faites preuve de pédagogie et soyez clair dans vos expliquations et processus de travail.  

## Séquence 4 : Documentation

Cette section explique comment utiliser ma solution **API-driven** pour piloter une instance EC2 simulée via API Gateway et Lambda dans LocalStack.

---

### Architecture mise en place
Une requête HTTP avec un paramètre `action` (start / stop / status) déclenche une fonction Lambda qui pilote l'état d'une instance EC2 simulée par LocalStack.

---

### Prérequis

- GitHub Codespaces ouvert sur ce repository
- Python 3.11 installé (présent par défaut sur Codespaces)
- LocalStack lancé (voir Séquence 2)

---

### Installation pas à pas

#### 1. Variables d'environnement AWS

Dans le terminal Codespaces, exporter les credentials factices pour LocalStack :

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=https://VOTRE_URL_CODESPACE-4566.app.github.dev/
```

Remplacer `VOTRE_URL_CODESPACE` par l'URL réelle du port 4566 exposé publiquement.

#### 2. Installation des outils

```bash
pip install awscli-local awscli
```

#### 3. Vérification que LocalStack fonctionne

```bash
awslocal sts get-caller-identity
```

Doit retourner un JSON avec `Account: 000000000000`.

---

### Création de l'infrastructure

#### Étape 1 : Créer une key-pair

```bash
awslocal ec2 create-key-pair --key-name ma-cle --query 'KeyMaterial' --output text > ma-cle.pem
chmod 400 ma-cle.pem
```

#### Étape 2 : Lancer une instance EC2

D'abord, lister les AMI disponibles :
```bash
awslocal ec2 describe-images --output table
```

Récupérer l'`ImageId` (exemple : `ami-07b643b5e45e` pour amazonlinux-2) puis :

```bash
awslocal ec2 run-instances \
  --image-id ami-07b643b5e45e \
  --instance-type t2.micro \
  --key-name ma-cle \
  --count 1
```

Noter l'`InstanceId` retourné (commence par `i-`).

#### Étape 3 : Créer le rôle IAM pour la Lambda

```bash
awslocal iam create-role \
  --role-name lambda-ec2-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
```

#### Étape 4 : Déployer la Lambda

Le fichier `lambda_function.py` contient la logique de pilotage de l'EC2. **Avant le déploiement**, remplacer la variable `INSTANCE_ID` dans le code par l'ID de l'instance créée à l'étape 2.

```bash
zip lambda_function.zip lambda_function.py

awslocal lambda create-function \
  --function-name ec2-controller \
  --runtime python3.11 \
  --handler lambda_function.lambda_handler \
  --role arn:aws:iam::000000000000:role/lambda-ec2-role \
  --zip-file fileb://lambda_function.zip \
  --timeout 30
```

#### Étape 5 : Créer l'API Gateway

```bash
API_ID=$(awslocal apigateway create-rest-api --name "ec2-api" --query 'id' --output text)
ROOT_ID=$(awslocal apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)
RESOURCE_ID=$(awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part "ec2" --query 'id' --output text)

awslocal apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method GET \
  --authorization-type NONE

awslocal apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:ec2-controller/invocations

awslocal apigateway create-deployment --rest-api-id $API_ID --stage-name dev
```

---

### Utilisation de la solution

Une fois l'infrastructure déployée, l'URL d'appel de l'API est :
http://localhost:4566/restapis/$API_ID/dev/_user_request_/ec2

Trois actions sont disponibles via le paramètre `?action=` :

| Action | Description |
|---|---|
| `status` | Affiche l'état actuel de l'instance |
| `start` | Démarre l'instance |
| `stop` | Arrête l'instance |

#### Exemples d'appels

**Vérifier l'état de l'instance :**
```bash
curl "http://localhost:4566/restapis/$API_ID/dev/_user_request_/ec2?action=status"
```

Réponse attendue :
```json
{"message": "Instance i-afff854eb5fd8f883 : etat = running", "action": "status"}
```

**Arrêter l'instance :**
```bash
curl "http://localhost:4566/restapis/$API_ID/dev/_user_request_/ec2?action=stop"
```

**Redémarrer l'instance :**
```bash
curl "http://localhost:4566/restapis/$API_ID/dev/_user_request_/ec2?action=start"
```

---

### Automatisation avec Makefile

Pour simplifier l'usage, un fichier `Makefile` est fourni à la racine du projet. Il permet d'exécuter les actions les plus courantes en une seule commande :

| Commande | Action |
|---|---|
| `make install` | Installe awslocal et les dépendances |
| `make ec2-create` | Crée une instance EC2 |
| `make lambda-deploy` | Zippe et déploie la Lambda |
| `make status` | Affiche l'état de l'instance via l'API |
| `make start` | Démarre l'instance via l'API |
| `make stop` | Arrête l'instance via l'API |
| `make clean` | Nettoie les fichiers temporaires |

---

### Workflow type

Pour relancer toute la solution depuis zéro :

```bash
# 1. Lancer LocalStack
localstack start -d

# 2. Exporter les variables AWS (voir plus haut)

# 3. Tout déployer
make install
make ec2-create
make lambda-deploy

# 4. Utiliser la solution
make status
make stop
make start
```

---

### Architecture détaillée

#### La fonction Lambda (`lambda_function.py`)

La fonction reçoit un événement HTTP de l'API Gateway au format `AWS_PROXY`. Elle extrait le paramètre `action` depuis `queryStringParameters` puis appelle les méthodes boto3 correspondantes (`start_instances`, `stop_instances`, `describe_instances`).

La connexion à EC2 se fait via `endpoint_url='http://localhost.localstack.cloud:4566'` car la Lambda doit pouvoir joindre LocalStack depuis son propre conteneur.

#### L'API Gateway

Une seule ressource `/ec2` avec une méthode `GET` est exposée. Elle est intégrée en mode `AWS_PROXY` à la Lambda, ce qui permet de passer directement la requête HTTP brute à la fonction sans transformation.

#### Pourquoi LocalStack ?

LocalStack simule l'API AWS sur le port 4566 sans avoir besoin de compte cloud réel ni de carte bancaire. C'est parfait pour apprendre et tester l'infrastructure as code sans risque de facturation imprévue.

---

### Problèmes rencontrés et solutions

**Erreur `PartialCredentialsError`** → Les variables `export` étaient collées sur une seule ligne. Solution : les coller une par une avec retours à la ligne.

**Erreur `InvalidAMIID.NotFound`** → L'AMI factice `ami-12345678` n'est plus accepté. Solution : utiliser un AMI pré-chargé par LocalStack listé avec `awslocal ec2 describe-images`.

**Erreur `Unknown options: --cli-binary-format`** → Cette option n'existe que sur AWS CLI v2. Solution : supprimer cette option ou installer AWS CLI v2.

---

### Conclusion

Cette solution démontre comment construire une architecture **serverless** réelle (Lambda + API Gateway) qui pilote dynamiquement de l'infrastructure cloud (EC2), le tout sans aucun coût grâce à LocalStack. Le même code fonctionnerait sur AWS réel en supprimant simplement la variable `endpoint_url` de boto3.
---------------------------------------------------
Evaluation
---------------------------------------------------
Cet atelier, **noté sur 20 points**, est évalué sur la base du barème suivant :  
- Repository exécutable sans erreur majeure (4 points)
- Fonctionnement conforme au scénario annoncé (4 points)
- Degré d'automatisation du projet (utilisation de Makefile ? script ? ...) (4 points)
- Qualité du Readme (lisibilité, erreur, ...) (4 points)
- Processus travail (quantité de commits, cohérence globale, interventions externes, ...) (4 points) 
