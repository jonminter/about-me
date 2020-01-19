serve:
	JEKYLL_GITHUB_TOKEN=`cat .gh-token` bundle exec jekyll serve --unpublished --future --drafts

serve-prod:
	JEKYLL_ENV=production JEKYLL_GITHUB_TOKEN=`cat .gh-token` bundle exec jekyll serve