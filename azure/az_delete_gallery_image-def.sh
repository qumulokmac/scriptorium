


GALLERYDEF="windows-maestro"
az sig image-version delete --gallery-image-definition ${GALLERYDEF} --gallery-name product_build_images  --resource-group crucible --gallery-image-version 0.0.4
az sig image-version delete --gallery-image-definition ${GALLERYDEF} --gallery-name product_build_images  --resource-group crucible --gallery-image-version 0.0.5
az sig image-version delete --gallery-image-definition ${GALLERYDEF} --gallery-name product_build_images  --resource-group crucible --gallery-image-version 0.0.6
az sig image-version delete --gallery-image-definition ${GALLERYDEF} --gallery-name product_build_images  --resource-group crucible --gallery-image-version 0.0.7
az sig image-definition delete --gallery-image-definition ${GALLERYDEF} --gallery-name product_build_images  --resource-group crucible 

sleep 5

az sig image-version list --gallery-image-definition maestro-linux-generic --gallery-name product_build_images --resource-group crucible
