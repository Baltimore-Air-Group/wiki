{{--
    BAG theme override of resources/views/layouts/parts/custom-head.blade.php

    Preserves BookStack's admin-defined custom head content, then layers
    on the BAG typography, theme stylesheet and permission-gating script.

    The inline <script> carries the CSP nonce ($cspNonce, shared on every
    view by ApplyCspRules); without it BookStack's strict-dynamic CSP
    would block it. The /theme/bag/* assets are same-origin ('self').
--}}
@inject('headContent', 'BookStack\Theming\CustomHtmlHeadContentProvider')

@if(!request()->routeIs('settings.category'))
<!-- Start: custom user content -->
{!! $headContent->forWeb() !!}
<!-- End: custom user content -->
@endif

{{-- BAG: typography (Inter, same CDN as the core app) --}}
<link rel="stylesheet" href="https://rsms.me/inter/inter.css">

{{-- BAG: theme styles. Bump ?v= when bag.css changes (1-day cache). --}}
<link rel="stylesheet" href="{{ url('/theme/bag/styles/bag.css') }}?v=1">

{{-- BAG: permission gating against the core API --}}
<script type="module" nonce="{{ $cspNonce }}">
  import { applyPermissionGates } from '{{ url('/theme/bag/scripts/bag.js') }}?v=1';
  applyPermissionGates();
</script>
