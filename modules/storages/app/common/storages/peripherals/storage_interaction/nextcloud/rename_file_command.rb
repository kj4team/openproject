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
  class RenameFileCommand
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(storage)
      @uri = storage.uri
      @base_path = Util.join_uri_path(@uri, "remote.php/dav/files", CGI.escapeURIComponent(storage.username))
      @username = storage.username
      @password = storage.password
    end

    def self.call(storage:, source:, target:)
      new(storage).call(source:, target:)
    end

    def call(source:, target:)
      response = Util
                   .httpx
                   .basic_auth(@username, @password)
                   .request(
                     "MOVE",
                     Util.join_uri_path(@base_path, Util.escape_path(source)),
                     headers: {
                       'Destination' => Util.join_uri_path(@uri.path, "remote.php/dav/files", CGI.escapeURIComponent(@username), Util.escape_path(target))
                     }
                   )

      case response.status
      when 201
        ServiceResult.success
      when 404
        Util.error(:not_found)
      when 401
        Util.error(:unauthorized)
      else
        Util.error(:error)
      end
    end
  end
end
