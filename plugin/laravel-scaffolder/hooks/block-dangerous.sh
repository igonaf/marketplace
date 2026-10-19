#!/usr/bin/env bash
input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<< "$input")

if grep -Eq 'artisan (migrate:fresh|migrate:reset|migrate:refresh|db:wipe)|rm -rf /' <<< "$cmd"; then
  echo "Заблоковано: деструктивна команда. Якщо її справді треба виконати, попроси мене пояснити, чому, або запусти вручну." >&2
  exit 2
fi

exit 0