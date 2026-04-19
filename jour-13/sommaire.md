# Sommaire du cours : Formation Complète – Azure Bicep

1. Introduction à Bicep  
   1.1 Qu’est-ce qu’Azure Bicep ?  
   1.2 Pourquoi utiliser Bicep plutôt que ARM JSON ?  
   1.3 Bicep vs Terraform  

2. Installation et configuration  
   2.1 Prérequis  
   2.2 Installation de Bicep  
   2.3 Extension VS Code  
   2.4 Authentification Azure  

3. Syntaxe fondamentale  
   3.1 Structure d’un fichier Bicep  
   3.2 Types de données  
   3.3 Fonctions intégrées courantes  
   3.4 Dépendances implicites  
   3.5 Dépendances explicites  

4. Paramètres et décorateurs  
   4.1 Décorateurs de paramètres  
   4.2 Valeurs par défaut  
   4.3 Fichier de paramètres (.bicepparam)  

5. Variables  

6. Boucles et déploiement conditionnel  
   6.1 Boucle `for` pour créer plusieurs ressources  
   6.2 Boucle avec condition  
   6.3 Déploiement conditionnel de ressources  
   6.4 Choix entre ressource nouvelle ou existante  

7. Modules – Réutiliser et organiser  
   7.1 Créer un module  
   7.2 Utiliser un module  
   7.3 Registre de modules public  
   7.4 Registre privé  

8. Déploiement avec Azure CLI  
   8.1 Déploiement de base  
   8.2 Validation avant déploiement (what-if)  
   8.3 Modes de déploiement  

9. Bonnes pratiques professionnelles  
   9.1 Nommage et conventions  
   9.2 Organisation du code  
   9.3 Sécurité  
   9.4 Gestion des environnements  
   9.5 Validation continue  

10. Exemples pratiques complets  
    10.1 Exemple 1 : Déployer un compte de stockage  
    10.2 Exemple 2 : VM complète avec VNet, NSG, IP publique  
    10.3 Exemple 3 : Architecture multi-environnements  

11. Nettoyage des ressources pour éviter la facturation  
    11.1 Supprimer un groupe de ressources (recommandé)  
    11.2 Supprimer des ressources individuelles  
    11.3 Nettoyage automatique via tags  
    11.4 Vérifier qu’il ne reste rien  

12. Intégration CI/CD (Azure Pipelines)  

13. Dépannage et erreurs courantes  

14. Conclusion