# UX Phase 11 — Feedback Visual

## Implementação: Toast Notifications + Loading States

### O que foi feito

#### 1. **Toast Component System** ✅
- **Arquivo:** `app/components/toast_component.rb`
- **Template:** `app/components/toast_component.html.erb`
- **Tipos:** success (verde), error (vermelho), info (azul)
- **Auto-dismiss:** 4 segundos ou clique manual em X
- **Animações:** Fade-in/out com `animate-toast-in` e `animate-toast-out`

#### 2. **Toast Controller (Stimulus)** ✅
- **Arquivo:** `app/javascript/controllers/toast_controller.js`
- **Funcionalidade:**
  - Auto-dismiss via `data-toast-auto-dismiss-value`
  - Duração configurável via `data-toast-duration-value`
  - Dismiss manual via botão

#### 3. **Animações Tailwind** ✅
- **Arquivo:** `app/assets/stylesheets/animations.tailwind.css`
- **Keyframes:**
  - `@keyframes toast-in` — slide-down + fade-in (300ms)
  - `@keyframes toast-out` — slide-up + fade-out (300ms)
  - `@keyframes button-pulse` — pulse sutil para loading

#### 4. **Loading States em Botões** ✅
- **Arquivos atualizados:**
  - `app/views/shared/_pick_button.html.erb`
  - `app/views/shared/_favorite_button.html.erb`
- **Funcionalidade:**
  - `data-disable-with` nativo do Rails
  - Estados visuais: `disabled:opacity-50 disabled:cursor-not-allowed`
  - Transições suaves: `transition-opacity`

#### 5. **Turbo Streams com Toast** ✅
- **Arquivos atualizados/criados:**
  - `app/views/picks/create.turbo_stream.erb`
  - `app/views/picks/destroy.turbo_stream.erb`
  - `app/views/favorites/create.turbo_stream.erb` (novo)
  - `app/views/favorites/destroy.turbo_stream.erb` (novo)
- **Pattern:**
  ```erb
  <%= turbo_stream.append "toasts-container" do %>
    <%= render ToastComponent.new(type: :success, message: "Epic picked! 🎵") %>
  <% end %>
  ```

#### 6. **Layout Container** ✅
- **Arquivo:** `app/views/layouts/application.html.erb`
- **Adição:** `<div id="toasts-container">` com `fixed top-4 right-4 z-50 space-y-2`

#### 7. **UI Helper** ✅
- **Arquivo:** `app/helpers/ui_helper.rb`
- **Função:** `spinner_icon` para SVG inline (preparado para uso futuro)

#### 8. **Testes** ✅
- **Arquivo:** `test/components/toast_component_test.rb`
- **Cobertura:**
  - Renderização de cada tipo (success, error, info)
  - Icones e cores corretas
  - Dismiss button presente
  - Atributos de acessibilidade (role, aria-live)
  - Controlador Stimulus registrado

### Fluxo de Uso

#### Exemplo: Pick Epic
1. Usuário clica no botão "Pick"
2. **Estado visual:** Botão desabilita com `disabled:opacity-50`
3. **Requisição:** POST via `button_to` (Turbo intercepta)
4. **Response:** `picks/create.turbo_stream.erb` renderiza:
   - Toast com mensagem "Epic picked! 🎵" (type: success)
   - Botão remontado (agora "Picked ✓")
   - Contador atualizado
   - Lista de pickers atualizada
5. **Animação:** Toast aparece com `animate-toast-in` e auto-dismiss em 4s

#### Estados de Erro
Se houver erro (ex: Epic privado):
```erb
<%= render ToastComponent.new(type: :error, message: "Cannot pick private Epic") %>
```

### Acessibilidade
- `role="alert"` para screen readers
- `aria-live="polite"` para notificações
- Botão de dismiss com `aria-label`
- Icons e text sempre combinados (não apenas visuais)

### Performance
- Componente ViewComponent (pré-renderizado)
- Animações CSS apenas (sem JavaScript custoso)
- Toast auto-dismiss (não precisa limpar manualmente)
- Turbo Streams: apenas elementos necessários recarregam

### Próximos Passos (Futuro)
- [ ] Toast com ações (ex: "Undo" button)
- [ ] Toast com ícone SVG em vez de emoji
- [ ] Toast em bottom-right (mobile-friendly)
- [ ] Stack tracking (evitar 20 toasts simultâneos)
- [ ] Sonoro opcional para ações críticas

---

## Testes

Rodar testes do Toast Component:
```bash
bin/rails test test/components/toast_component_test.rb
```

Rodar testes de Picks com Turbo Stream:
```bash
bin/rails test test/controllers/picks_controller_test.rb
```

Rodar testes de Favorites com Turbo Stream:
```bash
bin/rails test test/controllers/favorites_controller_test.rb
```

Rodar CI completo (incluindo system tests):
```bash
bin/ci
```

---

## Commits Sugeridos

1. `chore: add toast notification component`
2. `feat: add loading states to pick/favorite buttons`
3. `feat: integrate toast notifications with turbo streams`
4. `test: add toast component unit tests`
5. `refactor: update favorites controller to use turbo streams`
