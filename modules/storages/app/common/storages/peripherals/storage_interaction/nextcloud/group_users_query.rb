#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages::Peripherals::StorageInteraction::Nextcloud
  class GroupUsersQuery
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(storage)
      @uri = storage.uri
      @username = storage.username
      @password = storage.password
    end

    def self.call(storage:, group: storage.group)
      new(storage).call(group:)
    end

    # rubocop:disable Metrics/AbcSize
    def call(group:)
      response = Util
                   .httpx
                   .basic_auth(@username, @password)
                   .with(headers: {'OCS-APIRequest' => 'true'})
                   .get(Util.join_uri_path(@uri, "ocs/v1.php/cloud/groups", CGI.escapeURIComponent(group)))
      case response.status
      when 200
        group_users = Nokogiri::XML(response.body.to_s)
                        .xpath('/ocs/data/users/element')
                        .map(&:text)
        ServiceResult.success(result: group_users)
      when 405
        Util.error(:not_allowed)
      when 401
        Util.error(:unauthorized)
      when 404
        Util.error(:not_found)
      when 409
        Util.error(:conflict, error_text_from_response(response))
      else
        Util.error(:error)
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
