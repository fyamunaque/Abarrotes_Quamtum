// Activa los hooks de .githooks en este clon. Lo corre `npm install` (script "prepare").
import { execSync } from 'node:child_process';

try {
  execSync('git config core.hooksPath .githooks', { stdio: 'ignore' });
} catch {
  // Sin git o fuera de un repo (por ejemplo, un build en contenedor): no hace falta.
}
