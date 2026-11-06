const routines = {
  report: {
    title: 'Relatório semanal',
    steps: ['Reunir os dados da semana', 'Preencher o modelo', 'Salvar o relatório'],
    result: 'O relatório da semana foi montado e salvo na simulação.'
  },
  files: {
    title: 'Organizar arquivos',
    steps: ['Ler os nomes dos arquivos', 'Agrupar por projeto', 'Mover para as pastas correspondentes'],
    result: 'Os arquivos foram distribuídos por projeto na simulação.'
  },
  meeting: {
    title: 'Resumo de reunião',
    steps: ['Reunir as anotações', 'Separar decisões e próximos passos', 'Salvar o resumo'],
    result: 'O resumo ficou pronto com as decisões e os próximos passos.'
  }
};

const storageKey = 'sb-yimixvehxxglfjohenvr-auth-token';
const userMenu = document.querySelector('#userMenu');
const guestMenu = document.querySelector('#guestMenu');
const userEmail = document.querySelector('#userEmail');
const userAvatar = document.querySelector('#userAvatar');
const userAvatarPlaceholder = document.querySelector('#userAvatarPlaceholder');

function getInitials(email) {
  return email.split('@')[0].slice(0, 2).toUpperCase();
}

function getAvatarColor(email) {
  let hash = 0;
  for (let index = 0; index < email.length; index += 1) hash = email.charCodeAt(index) + ((hash << 5) - hash);
  return ['#145bdf', '#0d46b5', '#377af0', '#245eb6'][Math.abs(hash) % 4];
}

try {
  const session = JSON.parse(localStorage.getItem(storageKey) || 'null');
  const user = session?.user;
  if (user) {
    guestMenu.hidden = true;
    userMenu.hidden = false;
    const email = user.email || '';
    const avatarUrl = user.user_metadata?.avatar_url || user.user_metadata?.picture;
    userEmail.textContent = email;
    userEmail.title = email;
    if (avatarUrl) {
      userAvatar.src = avatarUrl;
      userAvatar.hidden = false;
    } else {
      userAvatarPlaceholder.textContent = getInitials(email);
      userAvatarPlaceholder.style.backgroundColor = getAvatarColor(email);
      userAvatarPlaceholder.hidden = false;
    }
  }
} catch {
  // Token inválido: mantém o menu de visitante.
}

const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
const compactLayout = window.matchMedia('(max-width: 730px)');
const hero = document.querySelector('.hero');
const mechanism = document.querySelector('.mechanism-grid');
const frame = document.querySelector('.mechanism-frame');
const chapters = [...document.querySelectorAll('.mechanism-step')];
const frameStage = frame.querySelector('.frame-stage');
const frameNumber = frame.querySelector('.frame-number');
const frameLabel = frame.querySelector('.frame-label');
const frameTitle = frame.querySelector('.frame-title');
const frameInfo = frame.querySelector('.frame-info');
const revealItems = document.querySelectorAll('[data-reveal]');

const stages = [
  { label: 'REGISTRO', title: 'Ações observadas' },
  { label: 'APRENDIZADO', title: 'Padrão identificado' },
  { label: 'AUTOMAÇÃO', title: 'Fluxo pronto para rodar' }
];

const revealObserver = 'IntersectionObserver' in window
  ? new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        revealObserver.unobserve(entry.target);
      }
    }
  }, { threshold: .08 })
  : null;

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);
let scrollFrame = 0;
let activeStage = 0;
let stageMotion;

function showStage(index) {
  activeStage = index;
  const number = String(index + 1).padStart(2, '0');
  frame.dataset.stage = index;
  frameStage.textContent = number + ' / 03';
  frameNumber.textContent = number;
  frameLabel.textContent = stages[index].label;
  frameTitle.textContent = stages[index].title;
  if (!reducedMotion.matches) {
    stageMotion?.cancel();
    stageMotion = frameInfo.animate(
      [{ opacity: .25, transform: 'translateY(10px)' }, { opacity: 1, transform: 'translateY(0)' }],
      { duration: 360, easing: 'cubic-bezier(.22, 1, .36, 1)' }
    );
  }
}

function updateScroll() {
  scrollFrame = 0;
  const viewport = window.innerHeight;
  const heroBounds = hero.getBoundingClientRect();
  if (!reducedMotion.matches && !compactLayout.matches && heroBounds.bottom > 0) {
    const distance = clamp(-heroBounds.top, 0, heroBounds.height);
    hero.style.setProperty('--hero-offset', distance * .16 + 'px');
  } else {
    hero.style.removeProperty('--hero-offset');
  }

  const bounds = mechanism.getBoundingClientRect();
  if (bounds.bottom <= 0 || bounds.top >= viewport) return;

  const readingLine = viewport * (compactLayout.matches ? .63 : .53);
  const stepBounds = chapters.map(chapter => chapter.getBoundingClientRect());
  const index = Math.max(0, stepBounds.findLastIndex(step => step.top <= readingLine));
  if (index !== activeStage) showStage(index);

  if (!reducedMotion.matches) {
    const first = stepBounds[0];
    const last = stepBounds.at(-1);
    const distance = last.top - first.top + last.height * .35;
    const progress = clamp((readingLine - first.top) / distance, 0, 1);
    frame.style.setProperty('--flow-progress', .1 + progress * .9);
  }
}

function scheduleScrollUpdate() {
  if (!scrollFrame) scrollFrame = window.requestAnimationFrame(updateScroll);
}

function configureMotion() {
  const enabled = !reducedMotion.matches;
  document.documentElement.classList.toggle('motion', enabled && Boolean(revealObserver));
  for (const item of revealItems) {
    if (enabled && !item.classList.contains('is-visible')) revealObserver?.observe(item);
    if (!enabled) revealObserver?.unobserve(item);
  }
  if (!enabled) {
    stageMotion?.cancel();
    frame.style.removeProperty('--flow-progress');
  }
  scheduleScrollUpdate();
}

window.addEventListener('scroll', scheduleScrollUpdate, { passive: true });
window.addEventListener('resize', scheduleScrollUpdate);
reducedMotion.addEventListener('change', configureMotion);
configureMotion();

const scenarioPicker = document.querySelector('.scenarios');
const routineTitle = document.querySelector('#routine-title');
const routineState = document.querySelector('#routine-state');
const routineRows = [...document.querySelectorAll('#routine-steps li')];
const routineResult = document.querySelector('#routine-result');
const runButton = document.querySelector('#run-demo');
const runLabel = runButton.firstElementChild;
const idleMessage = routineResult.textContent;
let selectedRoutine = 'report';
let timer;

function setRowState(row, state, label) {
  row.dataset.state = state;
  row.querySelector('.routine-status').textContent = label;
}

function resetRoutine() {
  window.clearTimeout(timer);
  const routine = routines[selectedRoutine];
  routineTitle.textContent = routine.title;
  routineState.textContent = 'PRONTO';
  routineState.classList.remove('is-complete');
  routineResult.textContent = idleMessage;
  runLabel.textContent = 'Simular rotina';
  runButton.disabled = false;

  routineRows.forEach((row, index) => {
    row.querySelector('.routine-name').textContent = routine.steps[index];
    setRowState(row, 'waiting', 'AGUARDANDO');
  });
}

function runStep(index) {
  const row = routineRows[index];
  if (!row) {
    routineState.textContent = 'CONCLUÍDO';
    routineState.classList.add('is-complete');
    routineResult.textContent = routines[selectedRoutine].result;
    runLabel.textContent = 'Simular novamente';
    runButton.disabled = false;
    return;
  }

  setRowState(row, 'active', 'EM CURSO');
  timer = window.setTimeout(() => {
    setRowState(row, 'done', 'CONCLUÍDO');
    runStep(index + 1);
  }, 520);
}

scenarioPicker.addEventListener('change', event => {
  selectedRoutine = event.target.value;
  resetRoutine();
});

runButton.addEventListener('click', () => {
  resetRoutine();
  if (reducedMotion.matches) {
    routineRows.forEach(row => setRowState(row, 'done', 'CONCLUÍDO'));
    runStep(routineRows.length);
    return;
  }
  routineState.textContent = 'EM EXECUÇÃO';
  routineResult.textContent = 'Simulando a sequência de ações.';
  runLabel.textContent = 'Simulando…';
  runButton.disabled = true;
  runStep(0);
});

selectedRoutine = scenarioPicker.querySelector(':checked').value;
resetRoutine();
