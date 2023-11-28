<div class="bg-blue-100">
  Hello <%= name %>
  <img alt="rat" src="static/rat.webp" width=1200 height=700 />
  <ul>
    <% for _, item in ipairs(items) do %>
      <li>
        <%= item -%>
      </li>
    <% end %>
  </ul>
</div>
