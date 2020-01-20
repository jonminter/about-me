serve:
	JEKYLL_GITHUB_TOKEN=`cat .gh-token` bundle exec jekyll serve --unpublished --future --drafts

serve-prod:
	JEKYLL_ENV=production JEKYLL_GITHUB_TOKEN=`cat .gh-token` bundle exec jekyll serve

build:
	JEKYLL_GITHUB_TOKEN=`cat .gh-token` bundle exec jekyll build

build-preview:
	JEKYLL_GITHUB_TOKEN=`cat .gh-token` bundle exec jekyll build --unpublished --future --drafts

deploy-preview: build-preview
	cd _site && AWS_PROFILE=jonminter-dev-preview aws s3 sync . s3://dev.jonminter.preview && cd ..