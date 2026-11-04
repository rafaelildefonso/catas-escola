lucide.createIcons();

const STORAGE_KEY = 'sb-yimixvehxxglfjohenvr-auth-token';

const userMenu = document.getElementById('userMenu');
const guestMenu = document.getElementById('guestMenu');
const userAvatar = document.getElementById('userAvatar');
const userAvatarPlaceholder = document.getElementById('userAvatarPlaceholder');
const userEmail = document.getElementById('userEmail');

function getInitials(email) {
  const name = email.split('@')[0];
  return name.substring(0, 2).toUpperCase();
}

function getAvatarColor(email) {
  let hash = 0;
  for (let i = 0; i < email.length; i++) {
    hash = email.charCodeAt(i) + ((hash << 5) - hash);
  }
  const colors = ['#3B82F6', '#8B5CF6', '#EC4899', '#F59E0B', '#10B981', '#06B6D4', '#F97316', '#6366F1'];
  return colors[Math.abs(hash) % colors.length];
}

function checkAuth() {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  try {
    const session = JSON.parse(raw);
    return session?.user || null;
  } catch {
    return null;
  }
}

const user = checkAuth();

if (user) {
  guestMenu.style.display = 'none';
  userMenu.style.display = 'flex';

  const avatarUrl = user.user_metadata?.avatar_url || user.user_metadata?.picture;
  const email = user.email || '';

  userEmail.textContent = email;
  userEmail.title = email;

  if (avatarUrl) {
    userAvatar.src = avatarUrl;
    userAvatar.style.display = 'block';
    userAvatarPlaceholder.style.display = 'none';
  } else {
    userAvatarPlaceholder.textContent = getInitials(email);
    userAvatarPlaceholder.style.backgroundColor = getAvatarColor(email);
    userAvatarPlaceholder.style.display = 'flex';
    userAvatar.style.display = 'none';
  }
}
