dgtech-publish:
	cd dgacek_tech && hugo --minify && rsync -avz --delete public/ gacekd@s28.mydevil.net:/home/gacekd/domains/dgacek.tech/public_html

dgtech-run-server:
	cd dgacek_tech && hugo server --buildDrafts -D
