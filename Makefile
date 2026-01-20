dgtech-publish:
	cd dgacek_tech && rsync -avz --delete public/ gacekd@s28.mydevil.net:/home/gacekd/domains/dgacek.tech/public_html
