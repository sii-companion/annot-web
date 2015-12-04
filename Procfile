#web:   bundle exec thin start -p $PORT -e development -D --stats /stats --ssl
web: bundle exec rails server -e production -b 0.0.0.0 -p 8000
#web: bundle exec rails server -e development -b 0.0.0.0 -p 8000
worker: bundle exec sidekiq -e production -C config/sidekiq.yml
#worker: bundle exec sidekiq -C config/sidekiq.yml
