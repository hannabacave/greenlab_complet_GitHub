Il y a deux fonctions principales : 

main_greenlab qui fait tourner le modèle greenlab et enregistre les résultats dans results

main_estimation qui prend en entrée un fichier csv. Attention, il ne prend pas la première colonne car normalement dans la dernière version c'est la colonne des numéros des jours. Il fusionne les deux cotylédons. Puis estimes les paramètres demandés. Ensuite, il enregistre dans results par défaut (mais dans results/S003 par exemple si on lui demande). Les paramètres estimé sont eux aussi enregistre dans results/estimation_param et peuvent être réutilisé comme paramètres par défaut pour une autre estimation.


L'idée global est : 

De faire tourner main_estimation sur un pot représentatif d'un génotype dans le fichier de sortie Col par exemple
Puis de réutiliser ces paramètres estimé comme base pour les différentes conditions et les différents pots 


Structure : 

deux fichiers main
dossier utils avec les sous fonctions
dossier data : il y a actuellement les feuilles réordonnées du pot S003 de P3ID76 pour tester le code. Mais il n'est pas nécéssaire que le fichier csv de données soient dans data pour faire l'estimation (suffit de mettre le bon chemin)
dossier résults ou les résultats sont enregistré par défaut