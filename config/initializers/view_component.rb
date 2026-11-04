ActiveSupport.on_load(:view_component) do
  # Previews can live next to their component (app/components/<name>/preview.rb)
  # See https://github.com/palkan/view_component-contrib#organizing-components-or-sidecar-pattern-extended
  ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
  # `self.abstract_class = true` keeps a preview out of the list
  ViewComponent::Preview.extend ViewComponentContrib::Preview::Abstract
end
