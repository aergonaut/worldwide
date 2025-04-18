# frozen_string_literal: true

module Worldwide
  class Region
    # When faced with the question, "Is a postal code required in this country?", we treat the answer
    # as a tri-state configuration item.  "Recommended" means that we recommend that it be provided,
    # but you may still leave the zip field blank.
    REQUIRED = "required"
    RECOMMENDED = "recommended"
    OPTIONAL = "optional"

    # The default `.inspect` isn't a good fit for Region, because it can end up dumping a lot of info
    # as it walks the hierarchy of descendants.  So, instead, we provide our own `.inspect` that
    # only shows a restricted subset of the object's fields.
    INSPECTION_FIELDS = [
      :alpha_three,
      :building_number_required,
      :currency,
      :example_city,
      :example_city_zip,
      :example_address,
      :flag,
      :format,
      :format_extended,
      :group,
      :group_name,
      :cldr_code,
      :iso_code,
      :languages,
      :neighbours,
      :numeric_three,
      :priority,
      :week_start_day,
      :unit_system,
      :zip_autofill_enabled,
      :zip_example,
      :zip_regex,
      :zip_requirement,
      :additional_address_fields,
      :combined_address_format,
      :address1_regex,
    ]

    # A region may have more than one parent.
    # For example, Puerto Rico (PR/US-PR) is associated with both the US and the Caribbean (029)
    attr_accessor :parents

    # ISO-3166 three-letter code for this region, if there is one.
    # Otherwise, nil.
    attr_reader :alpha_three

    # In some countries, every address must have a building number.
    # In others (e.g., GB), some addresses rely on just a building name, not a number.
    # If we require a building number in an address, then this will be true.
    attr_accessor :building_number_required

    # In some countries, an address may have the building number in address2.
    # If we are allowed to have a building number in address2, then this will be true.
    attr_accessor :building_number_may_be_in_address2

    # Alternate codes which may be used to designate this region
    attr_accessor :code_alternates

    # The suggested currency for use in this region.
    # Note that this may not always be the official currency.
    # E.g., we return USD for VE, not VED.
    attr_accessor :currency

    # A major city in the given region that can be used as an example
    attr_accessor :example_city

    # A zip code in the given region that can be used as an example; corresponds to example_city
    attr_accessor :example_city_zip

    # A value that can be used to order zones
    # Some countries, Japan, for example, customarily order zones non-alphabetically.
    attr_accessor :priority

    # A full address in the given region that can be used as an example
    attr_accessor :example_address

    # Unicode codepoints for this region's flag emoji
    attr_accessor :flag

    # Hash of strings denoting how to format an address in this region.
    # The format is described in https://shopify.engineering/handling-addresses-from-all-around-the-world
    #   - address1: a street address (address line 1, with a buliding nmuber and street name)
    #   - address1_with_unit: address line 1 including a subpremise (unit, apartment, etc.)
    #   - edit: the fields to present on an address input form
    #   - show: how to arrange the fields when formatting an address for display
    attr_accessor :format

    # Hash of strings denoting how to format an address in this region, including substitute and/or additional fields.
    # The format is described in https://shopify.engineering/handling-addresses-from-all-around-the-world
    #   - edit: the fields to present on an address input form
    #   - show: how to arrange the fields when formatting an address for display
    attr_accessor :format_extended

    # The string that results from appending " Countries" to the adjectival form of the {group_name}
    # @example
    #   Worldwide.region(code: "CA").group == "North American Countries"
    attr_accessor :group

    # The continent that this region is part of.
    attr_accessor :group_name

    # If this flag is set, then we support provinces "under the hood" for this country, but we do not
    # show them as part of a formatted address.  If the province is missing, we will auto-infer it
    # based on the zip (note that this auto-inference may be wrong for some addresses near a border).
    attr_accessor :hide_provinces_from_addresses

    # Returns true if provinces should be ignored
    # Used when adding provinces to a country that has none as an intermediate step
    attr_accessor :ignore_provinces

    # The CLDR code for this region.
    attr_reader :cldr_code

    # The ISO-3166-2 code for this region (e.g. "CA", "CA-ON")
    # or, if there is no alpha-2 code defined for this region, a numeric code (e.g. "001").
    attr_reader :iso_code

    # Languages that are commonly used in this region.
    # Note that this may not be the same as the languages that are officially recognized there.
    # We present them in alphabetical order by language code.
    attr_accessor :languages

    # The code used by the legacy Shopify ecosystem for this region.
    # E.g., for MX-CMX it will return "DF".
    # This code should _never_ be shown in the user interface.
    attr_reader :legacy_code

    # The name used by the legacy Shopify ecosystem for this region.
    # E.g., "Sao Tome And[sic] Principe" for "ST".
    # This name should _never_ be shown in the user interface.
    attr_reader :legacy_name

    # Other names that may be used to refer to this region.
    # E.g., "Czech Republic" is also known as "Czechia".
    attr_accessor :name_alternates

    # iso_code values of regions (subdivisions) within the same country that border this region.
    # E.g., for CA-ON, the neighbouring zones are CA-MB, CA-NU and CA-QC.
    attr_accessor :neighbours

    alias_method :neighbors, :neighbours

    # The ISO-3166-1 three-digit code for this region (returned as a string to preserve
    # leading zeroes), e.g., "003".
    attr_reader :numeric_three

    # Some countries have a multi-part postal code, and we may in some cases encounter only the first part.
    # E.g., the GB code `SW1A 1AA` has a first part (outward code) of `SW1A`.
    # When validating such a partial postal code, it must match this regular expression.
    attr_accessor :partial_zip_regex

    # The telephone country dialing code for this region
    attr_accessor :phone_number_prefix

    # WARNING:  The sales tax (VAT) rate info here follows an overly simplistic model.
    # For example, in CA-ON,
    #   - groceries are zero-rated (no VAT)
    #   - books are taxed at 5% VAT
    #   - hammers are taxed at 13% VAT
    # Also, the VAT name should be translated, but we don't have a mechanism to do that here.
    # You'd be better off using a more sophisticated  implementation instead of these tax_xxx methods.

    # Value Added Tax (Sales Tax) name
    # Note that this should really be translated; showing this untranslated name to users is a bad idea.
    attr_reader :tax_name

    # Whether the region uses tax-inclusive pricing.
    attr_accessor :tax_inclusive

    # "generic" VAT tax rate on "most" goods
    attr_reader :tax_rate

    # The type of tax for this region, e.g. "harmonized"
    attr_accessor :tax_type

    # tags that help us group the region, e.g. "EU-member"
    attr_accessor :tags

    # If the region is within a single timezone, its Olson name will be given here.
    attr_accessor :timezone

    # If the region spans multiple timezones (and it has postal codes), then this attribute will
    # contain a hash table mapping from timezone name to a list of postal code prefixes.
    # We can use this information to determine the timezone for a given postal code.
    attr_accessor :timezones

    # Day of the week (English language string) on which the week is considered to start in this region.
    # E.g., "sunday"
    attr_accessor :week_start_day

    # The measurement system in use in this region.
    attr_accessor :unit_system

    # true iff zone.iso_code should be returned as the .short_name for zones of this region
    attr_accessor :use_zone_code_as_short_name

    # Some regions have only a single postal code value.
    # In such cases, we can autofill the zip field with the value from zip_example.
    attr_accessor :zip_autofill_enabled

    # An example of a valid postal code for this region
    attr_accessor :zip_example

    # Is a zip value required in this region?  (Possible values:  "optional", "recommended", "required")
    attr_writer :zip_requirement

    # A list of character sequences with which a postal code in this region may start.
    attr_accessor :zip_prefixes

    # A regular expression which postal codes in this region must match.
    attr_accessor :zip_regex

    # Hash of zips that are valid for more than one province
    attr_accessor :zips_crossing_provinces

    # Regions that are sub-regions of this region.
    attr_reader :zones

    # If true, then the province is optional for addresses in this region.
    attr_accessor :province_optional

    # An array of the additional address fields that are defined for this region
    attr_accessor :additional_address_fields

    # A hash of the rules for concatening the additional address fields into the standard fields
    attr_accessor :combined_address_format

    # An array of regex patterns of the address1 field, capturing the supported additional address fields
    attr_accessor :address1_regex

    def initialize(
      alpha_three: nil,
      continent: false,
      country: false,
      deprecated: false,
      cldr_code: nil,
      iso_code: nil,
      legacy_code: nil,
      legacy_name: nil,
      numeric_three: nil,
      province: false,
      short_name: nil,
      tax_name: nil,
      tax_rate: 0.0,
      use_zone_code_as_short_name: false
    )
      if iso_code.nil? && numeric_three.nil?
        raise ArgumentError, "At least one of iso_code: and numeric_three: must be provided"
      end

      @alpha_three = alpha_three&.to_s&.upcase
      @continent = continent
      @country = country
      @deprecated = deprecated
      @cldr_code = cldr_code
      @iso_code = iso_code&.to_s&.upcase
      @legacy_code = legacy_code
      @legacy_name = legacy_name
      @numeric_three = numeric_three&.to_s
      @province = province
      @short_name = short_name
      @tax_name = tax_name
      @tax_rate = tax_rate
      @use_zone_code_as_short_name = use_zone_code_as_short_name

      @additional_address_fields = []
      @combined_address_format = {}
      @address1_regex = []
      @building_number_required = false
      @building_number_may_be_in_address2 = false
      @currency = nil
      @flag = nil
      @format = {}
      @format_extended = {}
      @name_alternates = []
      @group = nil
      @group_name = nil
      @languages = []
      @neighbours = []
      @partial_zip_regex = nil
      @phone_number_prefix = nil
      @tags = []
      @tax_inclusive = false
      @timezone = nil
      @timezones = {}
      @unit_system = nil
      @week_start_day = nil
      @zip_autofill_enabled = false
      @zip_example = nil
      @zip_prefixes = []
      @zip_regex = nil
      @example_address = nil

      @parents = [].to_set
      @zones = []
      @zones_by_code = {}
    end

    def inspect
      "#<#{self.class.name}:#{object_id} #{inspected_fields}>"
    end

    # Relationships

    def add_zone(region)
      return if @zones.include?(region)

      region.parents << self
      @zones.append(region)
      add_zone_to_hash(region)
    end

    # Attributes

    def associated_country
      return self if country?

      parent_country
    end

    def associated_continent
      return self if continent?

      parents.each do |parent|
        candidate = parent.associated_continent
        return candidate unless candidate.nil?
      end

      nil
    end

    # The value with which to autofill the zip, if this region has zip autofill active;
    # otherwise, nil.
    def autofill_zip
      zip_example if @zip_autofill_enabled
    end

    # The value with which to autofill the city, if this region has a default city; otherwise, nil.
    def autofill_city(locale: I18n.locale)
      field(key: :city).autofill(locale: locale)
    end

    # Does this region require cities to be specified?
    def city_required?
      autofill_city(locale: :en).nil?
    end

    # Is this Region a continent?
    def continent?
      @continent
    end

    # Is this Region considered a "country" (top-level political entity "country or region")
    # in the view of the legacy Shopify ecosystem?
    def country?
      @country
    end

    def deprecated?
      @deprecated
    end

    # An Worldwide::Field that can be used to ask about the field, including
    # labels, error messages, and an autofill value if there is one.
    def field(key:)
      return nil unless country?

      Worldwide::Fields.field(country_code: iso_code, field_key: key)
    end

    # A user-facing name in the currently-active locale's language.
    def full_name(locale: I18n.locale)
      lookup_code = cldr_code

      if /^[0-9]+$/.match?(lookup_code) || lookup_code.length < 3
        Worldwide::Cldr.t("territories.#{lookup_code}", locale: locale, default: legacy_name)
      else
        Worldwide::Cldr.t("subdivisions.#{lookup_code}", locale: locale, default: legacy_name)
      end
    end

    # Does this region have postal codes?
    def has_zip?
      !!format["show"]&.include?("{zip}")
    end

    # Does this region have cities?
    def has_cities?
      !!format["show"]&.include?("{city}")
    end

    # Is this Region considered a "province" (political subdivision of a "country")?
    def province?
      @province
    end

    # A short-form name for this region, if there is a conventional short form.
    # E.g., returns "ON" for "CA-ON", but "Tokyo" for "JP-13".
    def short_name
      @short_name || full_name
    end

    # returns a Region that is a child of this Region
    def zone(code: nil, name: nil, zip: nil)
      count = 0
      count += 1 unless code.nil?
      count += 1 unless name.nil?
      count += 1 unless zip.nil?

      unless count == 1
        # More than one of code, name, or zip was given
        raise ArgumentError, "Must specify exactly one of code:, name: or zip:."
      end

      if Worldwide::Util.present?(code)
        search_code = code.to_s.upcase
        alt_search_code = "#{search_code[0..1]}-#{search_code[2..-1]}"
        zone = nil

        [search_code, alt_search_code].each do |candidate|
          zone = @zones_by_code[candidate]
          break if zone
        end

        return zone unless zone.nil?
      elsif Worldwide::Util.present?(name)
        search_name = name.upcase

        zones.find do |region|
          search_name == region.legacy_name&.upcase ||
            region.name_alternates&.any? { |a| search_name == a.upcase } ||
            search_name == region.full_name&.upcase ||
            search_name == I18n.with_locale(:en) { region.full_name&.upcase }
        end
      else # Worldwide::Util.present?(zip)
        zone_by_normalized_zip(
          Zip.normalize(country_code: iso_code, zip: zip),
          allow_partial_zip: hide_provinces_from_addresses,
        )
      end || Worldwide.unknown_region
    end

    # If the Region has an autofill zip, return the value that will be autofilled
    # Otherwise, return nil
    def zip_autofill
      zip_example if zip_autofill_enabled
    end

    # is a postal code required for this region?
    def zip_required?
      if @zip_requirement.nil?
        !zip_regex.nil?
      else
        REQUIRED == @zip_requirement
      end
    end

    # Returns whether (and how firmly) we require a value in the zip field
    # Possible returns:
    #  - "required" means a value must be supplied
    #  - "recommended" means a value is optional, but we recommend providing one
    #  - "optional" means a value is optional, and we say it is optional
    # @return [String]
    def zip_requirement
      @zip_requirement || (zip_required? ? REQUIRED : OPTIONAL)
    end

    # is a neighborhood required for this region?
    def neighborhood_required?
      additional_field_required?("neighborhood")
    end

    # is a street name required for this region?
    def street_name_required?
      additional_field_required?("streetName")
    end

    # is a street number required for this region?
    def street_number_required?
      additional_field_required?("streetNumber")
    end

    # is the given postal code value valid for this region?
    def valid_zip?(zip, partial_match: false)
      normalized = Zip.normalize(
        country_code: province? && associated_country.iso_code ? associated_country.iso_code : iso_code,
        zip: zip,
      )
      valid_normalized_zip?(normalized, partial_match: partial_match)
    end

    # are zones optional for this region?
    def province_optional?
      province_optional || !@zones&.any?(&:province?)
    end

    # Returns true if this country has zones defined, and has postal code prefix data for the zones
    def has_zip_prefixes?
      @zones&.any? do |zone|
        Util.present?(zone.zip_prefixes)
      end
    end

    private

    def add_zone_to_hash(zone)
      @zones_by_code[subdivision_code(zone.iso_code)] = zone if Util.present?(subdivision_code(zone.iso_code))
      @zones_by_code[zone.alpha_three] = zone if Util.present?(zone.alpha_three)
      @zones_by_code[zone.iso_code] = zone if Util.present?(zone.iso_code)
      @zones_by_code[zone.legacy_code] = zone if Util.present?(zone.legacy_code)
      @zones_by_code[zone.numeric_three] = zone if Util.present?(zone.numeric_three)
      zone.code_alternates&.each do |code|
        @zones_by_code[code] = zone
      end
    end

    def additional_field_required?(field_name)
      field = additional_address_fields.find { |f| f["name"] == field_name }
      field ? !!field["required"] : false
    end

    def answers_to_cldr_code(search_code)
      return false if Util.blank?(search_code) || Util.blank?(cldr_code)
      return true if search_code.casecmp(cldr_code).zero?

      pc = parent_country
      "#{pc&.cldr_code&.downcase}#{cldr_code.downcase}" == search_code.downcase
    end

    def answers_to_iso_code(search_code)
      return true if search_code == iso_code

      pc = parent_country
      "#{pc&.iso_code}-#{iso_code}" == search_code
    end

    def cross_border_zip_includes_province?(zip:, province_code:)
      return false unless country?

      return false if zips_crossing_provinces.nil? || zips_crossing_provinces.empty?

      (0..zip.size - 1).each do |length|
        prefix = zip[0..length]
        return true if zips_crossing_provinces[prefix]&.include?(province_code)
      end

      false
    end

    def inspected_fields
      INSPECTION_FIELDS.map { |field_name| "@#{field_name}=#{send(field_name).inspect}" }.join(", ")
    end

    def parent_country
      @parent_country ||= parents.find(&:country?)
    end

    # Checks whether the given value is acceptable according to the regular expression defined for the country.
    # @param value [String] for the postal code
    # @return [Boolean]
    def passes_country_zip_regexp?(value:, partial_match: false)
      if province?
        return associated_country.send(:passes_country_zip_regexp?, value: value, partial_match: partial_match)
      end

      return false if partial_match && partial_zip_regex.nil?

      regex_prefix = partial_match ? partial_zip_regex : zip_regex
      return true if regex_prefix.nil?

      adjusted_value = partial_match ? value.strip : value

      Util.present?(Regexp.new(regex_prefix).match(adjusted_value))
    end

    # Search a list of zip prefixes (by province or timezone) to find the element that corresponds to the zip
    #
    # prefixes is a hash mapping from Region objects (representing "provinces") to arrays of strings
    # (representing a prefix with which a zip may start for that province), e.g.:
    # {region1 => [prefix1a, prefix1b], region2 => [prefix2a], region3 => [prefix3a, prefix3b, prefix3c]}
    #
    # Returns the Region in which the zip belongs based on the prefix, or `nil` if no match is found.
    def search_prefixes_by_normalized_zip(prefixes:, zip:, allow_partial_zip: false)
      return nil if Worldwide::Util.blank?(prefixes)
      return nil if Worldwide::Util.blank?(zip)
      return nil unless allow_partial_zip || passes_country_zip_regexp?(value: zip)

      stripped = Zip.strip_optional_country_prefix(country_code: iso_code, zip: zip)

      prefixes.find do |_zone, zone_prefixes|
        zone_prefixes&.any? do |prefix|
          prefix.start_with?(stripped) || stripped.start_with?(prefix)
        end
      end&.first
    end

    def subdivision_code(iso_code)
      return iso_code if iso_code.nil? || iso_code.length < 3

      country_code, subdivision_code = iso_code.split("-")
      subdivision_code if country_code.casecmp(associated_country.iso_code).zero?
    end

    def valid_normalized_zip?(normalized, province_code: nil, partial_match: false)
      if country?
        country = self
      elsif province?
        country = associated_country
        province_code ||= legacy_code
      end

      # If we can't figure out which country is involved, then we cannot validate this zip
      return false if country.nil?

      # If the zip is blank, then that's only valid if the country does not require a zip
      return !country.zip_required? if Worldwide::Util.blank?(normalized)

      # If the country has a zip_regex defined, then the supplied zip must match that regex
      return false unless passes_country_zip_regexp?(value: normalized, partial_match: partial_match)

      # If the country has no zip_prefixes, then there's nothing more to check
      return true unless country.send(:has_zip_prefixes?)

      inferred_province = country.send(:zone_by_normalized_zip, normalized, allow_partial_zip: partial_match)

      # If no province is specified, and we were able to infer a province, then we'll consider the zip valid
      return true if inferred_province && province_code.nil?

      # If a province was specified, and it matches the inferred province, then we'll consider the zip valid
      return true if inferred_province&.legacy_code == province_code && !province_code.nil?

      # Just because we inferred a different province from the zip doesn't necessarily mean that it's invalid.
      # For example, 42223 is valid for both US-KY and US-TN, but we infer US-KY because we can only infer one.
      country.send(:cross_border_zip_includes_province?, zip: normalized, province_code: province_code)
    end

    def zone_by_normalized_zip(normalized, allow_partial_zip: false)
      prefixes = zones&.map do |zone|
        [zone, zone.zip_prefixes]
      end&.to_h

      search_prefixes_by_normalized_zip(
        prefixes: prefixes,
        zip: normalized,
        allow_partial_zip: allow_partial_zip,
      )
    end
  end
end
