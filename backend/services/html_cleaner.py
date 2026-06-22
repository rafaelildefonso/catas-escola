
from bs4 import BeautifulSoup, Comment
import re

def clean_html_for_ai(html_content: str, max_tokens_approx: int = 15000) -> str:
    """
    Sanitiza e otimiza HTML para processamento por IA.
    Objetivo: Maximizar sinal (conteúdo semântico) e minimizar ruído (scripts, styles, tracking).
    """
    if not html_content:
        return ""

    soup = BeautifulSoup(html_content, 'html.parser')

    # 1. Remover elementos irrelevantes para entendimento do conteúdo
    # Scripts e estilos são inúteis para a IA entender o contexto visual/semântico de texto
    for element in soup(["script", "style", "noscript", "iframe", "object", "embed", "svg", "canvas", "meta", "link", "head"]):
        element.decompose()

    # 2. Remover comentários HTML
    for comment in soup.find_all(string=lambda text: isinstance(text, Comment)):
        comment.extract()

    # 3. Limpar atributos: Manter apenas o necessário para identificação e contexto
    # 'id' e 'class' são úteis para a IA sugerir seletores CSS se necessário
    # 'href', 'src', 'alt', 'title', 'aria-*' são vitais para semântica
    allowed_attributes = {
        'href', 'src', 'alt', 'title', 'id', 'class', 'name', 'type', 
        'value', 'placeholder', 'aria-label', 'role', 'content'
    }

    for tag in soup.find_all(True):
        # Achatamento de hierarquia desnecessária? 
        # Cuidado aqui: remover divs wrapper pode quebrar layout mental da IA. 
        # Melhor limpar atributos.
        
        attrs = dict(tag.attrs)
        for attr in attrs:
            should_remove = False
            
            # Remover eventos JS inline (segurança + ruído)
            if attr.lower().startswith('on'):
                should_remove = True
            
            # Remove se não for allowed e não for data-
            elif attr not in allowed_attributes and not attr.startswith('data-'):
                should_remove = True
            
            if should_remove:
                tag.attrs.pop(attr, None)

    # 4. Remover tags vazias que não sejam "self-closing" úteis (como img, input)
    # Ex: <div></div>, <span></span>. Isso reduz muito o token count de frameworks SPA.
    for tag in soup.find_all(True):
        if not tag.get_text(strip=True) and tag.name not in ['img', 'input', 'br', 'hr']:
            tag.decompose()

    # 5. Converter o soup para string processada
    # 'prettify' pode adicionar muito whitespace extra, melhor controlar manualmente ou usar get_text se fosse só texto.
    # Mas aqui queremos HTML estruturado.
    cleaned_html = str(soup)

    # 6. Compressão de whitespace
    # Reduzir múltiplos espaços/newlines para 1, economizando tokens violentamente.
    cleaned_html = re.sub(r'\s+', ' ', cleaned_html).strip()

    # 7. Truncate inteligente (opcional, segurança contra payloads gigantes)
    # Um token ~= 4 chars. 15k tokens ~= 60k chars.
    limit_chars = max_tokens_approx * 4
    if len(cleaned_html) > limit_chars:
        cleaned_html = cleaned_html[:limit_chars] + "...[TRUNCATED]"

    return cleaned_html
