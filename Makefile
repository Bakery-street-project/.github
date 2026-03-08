bootstrap:
\t./infra/scripts/bootstrap_ubuntu.sh

agent-dev:
\tcd agent && . .venv/bin/activate && uvicorn app.main:app --reload --port 9000

tui-dev:
\tcd tui && cargo run

wallet-daemon:
\t./wallet/scripts/start_daemon.sh

stripe-listen:
\tcd payments && ./scripts/stripe_listen.sh
