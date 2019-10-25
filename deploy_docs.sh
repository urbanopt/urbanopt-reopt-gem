set -e
bundle exec rdoc --template-stylesheets ./docs/.vuepress/public/custom_rdoc_styles.css
npm run build --prefix docs
#npm run dev --prefix docs
npm run deploy --prefix docs