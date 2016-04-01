#!/bin/bash
# charset=utf-8


######################################################## Intro ########################################################


####### Supression des anciens fichiers pour eviter des residus parasites a chaque nouveau lancement du script 

rm -r ../contextes/*
rm -r ../pages_aspirees/*
rm -r ../pages_dump/*

####### supression optionnelle des tableaux precedents
#rm -r ../tableaux/*


####### Objets et fonctions preparatoires

echo "Ecrivez un nom pour le tableau (pas besoin d'ecrire .html)" ;
read nom_tableau ;

dossier_urls=../urls
#fichier_tableau=../tableaux/$nom_tableau.html 
fichier_tableau=../tableaux/$nom_tableau.html 

exec &> sortie.log

echo $dossier_urls
echo $fichier_tableau

compteur_tableau=1 ;
motif="((coc(h)?l(e|e)?a(i)?r(e|s)*?)?( )?implant(e|s)*?( )?(coc(h)?l(e|e)?a(i)?r(e|s)*?)?)|(\b( |')IC\b|\b CI(^-)\b)"


######################################################## Main ########################################################

####### Ouverture du fichier tableau
echo "<html><head></head><body>" > $fichier_tableau ;

####### Premiere boucle 'for' : lecture de chacun des fichiers contenant des urls (division des fichiers par langue), creation du tableau (1 par fichier contenant des urls)
for fichier in `ls $dossier_urls`
{
	compteur_ligne=1 ;
	
	echo "<table align=\"center\" border =\"1\">" >> $fichier_tableau ;
	echo "<tr><td align = \"center\" colspan=\"9\">Tableau $compteur_tableau </td></tr>" >> $fichier_tableau ;
	echo "<tr><td>--</td><td>- URL de la page -</td><td>- Page Aspir&eacute;e -</td><td>- Encodage -</td><td>- Converti en -</td><td>- Text Dump -</td><td>- Contexte Dump -</td><td>- Index -</td></tr>" >>$fichier_tableau
	
####### Deuxieme boucle 'for' :  lecture listee de chaque url contenue dans chacun des fichiers specifies dans la premiere boucle 'for'
	for line in `cat $dossier_urls/$fichier`
	
	
######################### Procesus d'aspiration	#########################
	{
		wget $line -O ../pages_aspirees/$compteur_tableau-$compteur_ligne.html ; 
		# il existe une methode optionnelle en utilisant 'curl'
		
####### Premiere condition 'if' : si l'aspiration s'est bien deroulee on tente d'obtenir l'encodage via le 'charset' de la page aspiree
		if [[ $? == 0 ]]
			then 
			encodagegrep=$(egrep --binary-file=text -oi -m 1 "meta(.*)charset[^=]*?=*?\"?[^\"\']+?" ../pages_aspirees/$compteur_tableau-$compteur_ligne.html | egrep --binary-file=text -oi "charset[^=]*?=*?\"?[^\"\']+?" | cut -f2 -d= | tr -d " \"" | tr [A-Z] [a-z]) ; 
			echo $encodagegrep ;
			
			
####### Deuxieme condition 'if' : si l'encodage de la page aspiree est de l'utf-8 
			if [[ $encodagegrep == "utf-8" ]]
				then
				
				# dump + contexte + index
				lynx -dump -nolist -assume_charset=$encodagegrep -display_charset=$encodagegrep $line > ../pages_dump/brut$compteur_tableau-$compteur_ligne.txt ;
				sed 's/^[\t| \s]*//;/^\(#\|*\|+\|o \)/d' ../pages_dump/brut$compteur_tableau-$compteur_ligne.txt | awk '!a[$0]'++ > ../pages_dump/$compteur_tableau-$compteur_ligne.txt ;
                egrep -i -1 $motif ../pages_dump/$compteur_tableau-$compteur_ligne.txt > ../contextes/$compteur_tableau-$compteur_ligne.txt ;
				egrep -o "\w+" ../pages_dump/$compteur_tableau-$compteur_ligne.txt | sort | uniq -c | sort -r > ../pages_dump/$compteur_tableau-${compteur_ligne}_index.txt ;
				
				# remplissage tableau
				echo "<tr><td>Lien n&deg; $compteur_ligne</td><td><a href=\"$line\">URL n&deg;$compteur_ligne</a></td><td><a href=\"../pages_aspirees/$compteur_tableau-$compteur_ligne.html\">PA n&deg;$compteur_ligne</a></td><td>$encodagegrep</td><td>--</td><td><a href=\"../pages_dump/$compteur_tableau-$compteur_ligne.txt\"> Text Dump n&deg;$compteur_ligne</a></td><td><a href=\"../contextes/$compteur_tableau-$compteur_ligne.txt\"> Contexte Dump $compteur_tableau-$compteur_ligne</a></td><td><a href=\"../pages_dump/$compteur_tableau-${compteur_ligne}_index.txt\">Index n&deg;$compteur_tableau-$compteur_ligne</a></td></tr>" >> $fichier_tableau ;
				
				#dump global + contexte global
				cat ../pages_dump/$compteur_tableau-$compteur_ligne.txt >> ../pages_dump/globaldump-$compteur_tableau.txt ;
				cat ../contextes/$compteur_tableau-$compteur_ligne.txt >> ../contextes/globalcontextes-$compteur_tableau.txt ;
			
####### 'Else' complementaire de la deuxieme condition 'if' : si l'encodage de la page aspiree n'est pas de l'utf-8
			else
				encodageiconv=$(iconv -l | egrep -oi "\b$encodagegrep\b") ;
				
####### Troisieme condition 'if' : si l'encodage de la page aspiree est connue de 'iconv'
				if [[ $encodageiconv == "" ]]
					then
					encodagefile=$(file -i ../pages_aspirees/$compteur_tableau-$compteur_ligne.html | cut -f2 -d=) ;
					encodageiconv=$(iconv -l | egrep -oi "\b$encodagefile\b") ;
						
####### Quatrieme condition 'if' : si l'encodage connu de 'file' est de l'utf-8
						if [[ $encodagefile == "utf-8" ]]
						then
						
							# dump + contexte + index
							lynx -dump -nolist -assume_charset=$encodagegrep -display_charset=$encodagegrep $line > ../pages_dump/brut$compteur_tableau-$compteur_ligne.txt ;
							sed 's/^[\t| \s]*//;/^\(#\|*\|+\|o \)/d' ../pages_dump/brut$compteur_tableau-$compteur_ligne.txt | awk '!a[$0]'++ > ../pages_dump/$compteur_tableau-$compteur_ligne.txt ;
							
							egrep -i -1 $motif ../pages_dump/$compteur_tableau-$compteur_ligne.txt > ../contextes/$compteur_tableau-$compteur_ligne.txt ;
							egrep -o "\w+" ../pages_dump/$compteur_tableau-$compteur_ligne.txt | sort | uniq -c | sort -r > ../pages_dump/$compteur_tableau-${compteur_ligne}_index.txt ;
							echo "encodage file : $encodafile" ;
							
							# remplissage tableau
							echo "<tr><td>Lien n&deg; $compteur_ligne</td><td><a href=\"$line\">URL n&deg;$compteur_ligne</a></td><td><a href=\"../pages_aspirees/$compteur_tableau-$compteur_ligne.html\">PA n&deg;$compteur_ligne</a></td><td>$encodagefile</td><td>--</td><td><a href=\"../pages_dump/$compteur_tableau-$compteur_ligne.txt\"> Text Dump n&deg;$compteur_ligne</a></td><td><a href=\"../contextes/$compteur_tableau-$compteur_ligne.txt\"> Contexte Dump $compteur_tableau-$compteur_ligne</a></td><td><a href=\"../pages_dump/$compteur_tableau-${compteur_ligne}_index.txt\">Index n&deg;$compteur_tableau-$compteur_ligne</a></td></tr>" >> $fichier_tableau ;
							
							#dump global + contexte global
							cat ../pages_dump/$compteur_tableau-$compteur_ligne.txt >> ../pages_dump/globaldump-$compteur_tableau.txt ;
							cat ../contextes/$compteur_tableau-$compteur_ligne.txt >> ../contextes/globalcontextes-$compteur_tableau.txt ;
							
####### 'Else' complementaire de la quatrieme condition 'if' : si l'encodage connu de 'file' n'est pas de l'utf-8
						else
							
####### Cinquieme condition 'if' : si l'encodage connu de 'file' n'est pas de l'utf-8 mais il est connu de 'iconv'
							if [[ $encodageiconv == "" ]]
							then
							
							# remplissage tableau
							echo "<tr><td>Lien n&deg; $compteur_ligne</td><td><a href=\"$line\">URL n&deg;$compteur_ligne</a></td><td><a href=\"../pages_aspirees/$compteur_tableau-$compteur_ligne.html\">PA n&deg;$compteur_ligne</a></td><td> Non sp&eacute;cifi&eacute; </td><td> -- </td><td> -- </td><td> -- </td><td> -- </td><td> -- </td></tr>" >>$fichier_tableau ;
							
####### 'Else' complementaire de la cinquieme condition 'if' : si l'encodage connu de 'file' n'est pas de l'utf-8 et il n'est pas connu de 'iconv'
							else
								
								# dump + conversion iconv + contexte + index
								lynx -dump -nolist -assume_charset=$encodagegrep -display_charset=$encodagegrep $line > ../pages_dump/brut$compteur_tableau-$compteur_ligne.txt ;
								sed 's/^[\t| \s]*//;/^\(#\|*\|+\|o \)/d' ../pages_dump/brut$compteur_tableau-$compteur_ligne.txt | awk '!a[$0]'++ > ../pages_dump/$compteur_tableau-$compteur_ligne.txt ;
								
								iconv -f $encodageiconv -t utf-8 ../pages_dump/$compteur_tableau-$compteur_ligne.txt > ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt ;
								egrep -i -1 "((coc(h)?l(e|e)?a(i)?r(e|s)*?)?( )?implant(e|s)*?( )?(coc(h)?l(e|e)?a(i)?r(e|s)*?)?)|(\b( |')IC\b|\b CI(^-)\b)" ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt > ../contextes/$compteur_tableau-${compteur_ligne}_UTF8.txt ;
								egrep -o "\w+" ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt | sort | uniq -c | sort -r > ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8_index.txt ;
								
								# remplissage tableau
								echo "<tr><td>Lien n&deg; $compteur_ligne</td><td><a href=\"$line\">URL n&deg;$compteur_ligne</a></td><td><a href=\"../pages_aspirees/$compteur_tableau-$compteur_ligne.html\">PA n&deg;$compteur_ligne</a></td><td>$encodagefile</td><td>utf-8</td><td><a href=\"../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt\"> Text Dump n&deg;$compteur_ligne</a></td><td><a href=\"../contextes/$compteur_tableau-${compteur_ligne}_UTF8.txt\"> Contexte Dump $compteur_tableau-$compteur_ligne</a></td><td><a href=\"../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8_index.txt\">Index n&deg;$compteur_tableau-$compteur_ligne</a></td></tr>" >> $fichier_tableau ;
								
								#dump global + contexte global
								cat ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt >> ../pages_dump/globaldump-$compteur_tableau.txt ;
								cat ../contextes/$compteur_tableau-${compteur_ligne}_UTF8.txt >> ../contextes/globalcontextes-$compteur_tableau.txt ;
								
								#contextes mini-grep
								
								#perl ../minigrepmultilingue-v2.2-regexp/minigrepmultilingue.pl "utf-8" ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt ../minigrepmultilingue-v2.2-regexp/motif-regexp.txt ;
								#mv ../minigrepmultilingue-v2.2-regexp/resultat-extraction.html ../contextes/$compteur_tableau-${compteur_ligne}_UTF8.html ;
							fi
						fi
					
####### 'Else' complementaire de la troisieme condition 'if' : si l'encodage de la page aspiree n'est pas connue de 'iconv'
				else
					
					# dump + conversion iconv + contexte + index
					lynx -dump -nolist -assume_charset=$encodagegrep -display_charset=$encodagegrep $line > ../pages_dump/brut$compteur_tableau-$compteur_ligne.txt ;
					sed 's/^[\t| \s]*//;/^\(#\|*\|+\|o \)/d' ../pages_dump/brut$compteur_tableau-$compteur_ligne.txt | awk '!a[$0]'++ > ../pages_dump/$compteur_tableau-$compteur_ligne.txt ;
					
					iconv -f $encodageiconv -t utf-8 ../pages_dump/$compteur_tableau-$compteur_ligne.txt > ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt ;
					egrep -i -1 $motif ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt > ../contextes/$compteur_tableau-${compteur_ligne}_UTF8.txt ;
					egrep -o "\w+" ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt | sort | uniq -c | sort -r > ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8_index.txt ;
					
					# remplissage tableau
					echo "<tr><td>Lien n&deg; $compteur_ligne</td><td><a href=\"$line\">URL n&deg;$compteur_ligne</a></td><td><a href=\"../pages_aspirees/$compteur_tableau-$compteur_ligne.html\">PA n&deg;$compteur_ligne</a></td><td>$encodagegrep</td><td>utf-8</td><td><a href=\"../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt\"> Text Dump n&deg;$compteur_ligne</a></td><td><a href=\"../contextes/$compteur_tableau-${compteur_ligne}_UTF8.txt\"> Contexte Dump $compteur_tableau-$compteur_ligne</a></td><td><a href=\"../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8_index.txt\">Index n&deg;$compteur_tableau-$compteur_ligne</a></td></tr>" >> $fichier_tableau ;
					
					#dump global + contexte global
					cat ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt >> ../pages_dump/globaldump-$compteur_tableau.txt ;
					cat ../contextes/$compteur_tableau-${compteur_ligne}_UTF8.txt >> ../contextes/globalcontextes-$compteur_tableau.txt ;
					
					#contextes mini-grep
					
					#perl ../minigrepmultilingue-v2.2-regexp/minigrepmultilingue.pl "utf-8" ../pages_dump/$compteur_tableau-${compteur_ligne}_UTF8.txt ../minigrepmultilingue-v2.2-regexp/motif-regexp.txt ;
					#mv ../minigrepmultilingue-v2.2-regexp/resultat-extraction.html ../contextes/$compteur_tableau-${compteur_ligne}_UTF8.html ;
				fi
			fi
		fi
		
		# compteur de ligne
		let "compteur_ligne=compteur_ligne+1" ;
	}
	
####### Fermeture de chaque tableau
	echo "</table>" >> $fichier_tableau ;
	echo "<br />" >> $fichier_tableau ;
	echo -"<table align=\"center\" border =\"1\">" >> $fichier_tableau ;
	echo "<tr><td align=\"center\" colspan = \"2\"> Fichiers Globaux du tableau n&deg;$compteur_tableau</td></tr>" >> $fichier_tableau ;
	echo "<tr><td><a href=\"../pages_dump/globaldump-$compteur_tableau.txt\">Global Dump</a></td><td><a href=\"../contextes/globalcontextes-$compteur_tableau.txt\" > Global Context </a></td></tr>" >> $fichier_tableau ;
	echo "</table><br /><br />" >> $fichier_tableau ;
	
	#compteur de tableau
	let "compteur_tableau=compteur_tableau+1";
}

####### Fermeture du fichier tableau
echo "</body></html>" >> $fichier_tableau ;




