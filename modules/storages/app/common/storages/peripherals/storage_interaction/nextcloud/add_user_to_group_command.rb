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
  class AddUserToGroupCommand
    def initialize(storage)
      @uri = storage.uri
      @username = storage.username
      @password = storage.password
      @group = storage.group
    end

    # rubocop:disable Metrics/AbcSize
    def self.call(storage:, user:, group: storage.group)
      new(storage).call(user:, group:)
    end

    def call(user:, group: @group)
      response = Util
                   .httpx
                   .basic_auth(@username, @password)
                   .with(headers: { 'OCS-APIRequest' => 'true' })
                   .post(
                     Util.join_uri_path(
                       @uri,
                       'ocs/v1.php/cloud/users',
                       CGI.escapeURIComponent(user),
                       'groups'
                     ),
                     form: { "groupid" => CGI.escapeURIComponent(group) },
                   )

      case response.status
      when 200
        statuscode = Nokogiri::XML(response.body.to_s).xpath('/ocs/meta/statuscode').text
        case statuscode
        when "100"
          ServiceResult.success(message: "User has been added successfully")
        when "101"
          Util.error(:error, "No group specified")
        when "102"
          Util.error(:error, "Group does not exist")
        when "103"
          Util.error(:error, "User does not exist")
        when "104"
          Util.error(:error, "Insufficient privileges")
        when "105"
          Util.error(:error, "Failed to add user to group")
        end
      when 405
        Util.error(:not_allowed)
      when 401
        Util.error(:unauthorized)
      when 404
        Util.error(:not_found)
      when 409
        Util.error(:conflict)
      else
        Util.error(:error)
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
