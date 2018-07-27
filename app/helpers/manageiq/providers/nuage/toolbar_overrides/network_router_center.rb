module ManageIQ
  module Providers
    module Nuage
      module ToolbarOverrides
        class NetworkRouterCenter < ::ApplicationHelper::Toolbar::Override
          button_group(
            'nuage_network_router',
            [
              select(
                :nuage_network_router,
                'fa fa-cog fa-lg',
                t = N_('Edit'),
                t,
                :items => [
                  button(
                    :nuage_create_cloud_subnet,
                    'pficon pficon-add-circle-o fa-lg',
                    t = N_('Create L3 Cloud Subnet'),
                    t,
                    :data  => {'function'      => 'sendDataWithRx',
                               'function-data' => {:controller     => 'provider_dialogs',
                                                   :button         => :nuage_create_cloud_subnet,
                                                   :modal_title    => N_('Create L3 Cloud Subnet'),
                                                   :component_name => 'CreateNuageCloudSubnetForm'}.to_json},
                    :klass => ApplicationHelper::Button::ButtonWithoutRbacCheck
                  ),
                ]
              )
            ]
          )
        end
      end
    end
  end
end
