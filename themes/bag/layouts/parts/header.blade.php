{{--
    BAG theme override of resources/views/layouts/parts/header.blade.php

    Mirrors the upstream header verbatim so the mobile toggle, search and
    user-menu components keep working. The only BAG additions are:
      - a `bag-header` class hook for bag.css
      - a small "Back to BAG" link into the nav (theme guide section 7:
        BookStack is *a* surface, not the home base).
--}}
<header id="header" component="header-mobile-toggle" class="primary-background px-xl grid print-hidden bag-header">
    <div class="flex-container-row justify-space-between gap-s items-center">
        @include('layouts.parts.header-logo')
        <div class="hide-over-l py-s">
            <button type="button"
                    refs="header-mobile-toggle@toggle"
                    title="{{ trans('common.header_menu_expand') }}"
                    aria-expanded="false"
                    class="mobile-menu-toggle">@icon('more')</button>
        </div>
    </div>

    <div class="flex-container-column items-center justify-center hide-under-l">
    @if(user()->hasAppAccess())
        @include('layouts.parts.header-search')
    @endif
    </div>

    <nav refs="header-mobile-toggle@menu" class="header-links">
        <div class="links text-center">
            <a href="https://baltimoreairgroup.org" class="bag-back-link">@icon('back')<span>Back to BAG</span></a>
            @include('layouts.parts.header-links')
        </div>
        @if(!user()->isGuest())
            @include('layouts.parts.header-user-menu', ['user' => user()])
        @endif
    </nav>
</header>
