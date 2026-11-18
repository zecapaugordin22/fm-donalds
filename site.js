const menuToggle = document.querySelector(".menu-toggle");
const navLinks = document.querySelector(".nav-links");

menuToggle.addEventListener("click", () => {
  const isOpen = navLinks.classList.toggle("is-open");
  menuToggle.setAttribute("aria-expanded", isOpen);
  menuToggle.setAttribute("aria-label", isOpen ? "Fechar menu" : "Abrir menu");
});

navLinks.addEventListener("click", (event) => {
  if (!event.target.closest("a")) return;
  navLinks.classList.remove("is-open");
  menuToggle.setAttribute("aria-expanded", "false");
  menuToggle.setAttribute("aria-label", "Abrir menu");
});

async function loadPromotions() {
  const config = window.SUPABASE_CONFIG;
  if (!config?.url || !config?.anonKey || config.url.includes("SEU-PROJETO") || config.anonKey.includes("SUA_CHAVE")) return;

  const endpoint = new URL("/rest/v1/promotions", config.url);
  endpoint.search = new URLSearchParams({
    select: "label,title,description,products!inner(image_url,image_alt,active)",
    active: "eq.true",
    "products.active": "eq.true",
    order: "position.asc"
  });

  try {
    const response = await fetch(endpoint, {
      headers: {
        apikey: config.anonKey,
        Authorization: `Bearer ${config.anonKey}`
      }
    });
    if (!response.ok) throw new Error(`Supabase respondeu ${response.status}`);

    const promotions = await response.json();
    if (!Array.isArray(promotions) || promotions.length === 0) return;

    const grid = document.querySelector(".promo-grid");
    const cards = promotions.map((promotion) => {
      const product = Array.isArray(promotion.products) ? promotion.products[0] : promotion.products;
      if (!product) return null;

      const card = document.createElement("article");
      card.className = "promo-card";
      const image = document.createElement("img");
      image.className = "promo-image";
      image.src = product.image_url || "";
      image.alt = product.image_alt || promotion.title;
      image.loading = "lazy";
      const body = document.createElement("div");
      body.className = "promo-body";
      const label = document.createElement("span");
      label.className = "promo-label";
      label.textContent = promotion.label;
      const title = document.createElement("h3");
      title.textContent = promotion.title;
      const description = document.createElement("p");
      description.textContent = promotion.description;
      const link = document.createElement("a");
      link.className = "text-link";
      link.href = "#sobre";
      link.textContent = "Quero conhecer →";
      body.append(label, title, description, link);
      card.append(image, body);
      return card;
    }).filter(Boolean);

    if (cards.length) grid.replaceChildren(...cards);
  } catch (error) {
    console.error("Não foi possível carregar as ofertas do Supabase:", error);
  }
}

loadPromotions();
