#!/bin/sh
set -e

cd /app

if [ ! -f config.py ]; then
  cp config_template.py config.py
fi

if [ -n "$OPENAI_API_KEY" ]; then
  python - <<'PY'
from pathlib import Path
import re, os
path = Path('config.py')
text = path.read_text()
text = re.sub(r'^OPENAI_API_KEY\s*=.*$', f'OPENAI_API_KEY = "{os.environ["OPENAI_API_KEY"]}"', text, flags=re.M)
if os.environ.get('WEB_PORT'):
    text = re.sub(r'^WEB_PORT\s*=.*$', f'WEB_PORT = {os.environ["WEB_PORT"]}', text, flags=re.M)
path.write_text(text)
PY
fi

exec python web/web_interface.py
